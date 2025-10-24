// Your ReceivePage.dart code (already corrected in previous turn)
import 'package:delivery/user/detail.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/search.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipPath(
          clipper: CustomAppBarClipper(borderRadius: 30.0),
          child: Container(
            color: const Color(0xFFFDE428),
            padding:
                const EdgeInsets.only(top: 45, left: 20, right: 20, bottom: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.black, size: 24),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryPage()));
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'ส่งสินค้า',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 20.0),
            child: _buildContentTitle(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('packages')
                  .where('sender_user_id',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('status', whereIn: ['pending', 'accepted', 'on_delivery'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีรายการจัดส่งที่กำลังดำเนินการ'));
                }

                final activePackages = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: activePackages.length,
                  itemBuilder: (context, index) {
                    final packageDoc = activePackages[index];
                    final packageData =
                        packageDoc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildDeliveryCard(context,
                          packageId: packageDoc.id, packageData: packageData),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // This is correct: pushes SearchRecipientScreen on top
                  Navigator.push( 
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchRecipientScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 5,
                ),
                child: const Text(
                  'ส่งสินค้า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context, {
    required String packageId,
    required Map<String, dynamic> packageData,
  }) {
    final senderInfo =
        packageData['sender_info'] as Map<String, dynamic>? ?? {};
    final receiverInfo =
        packageData['receiver_info'] as Map<String, dynamic>? ?? {};
    final imageUrl = packageData['proof_image_url'] as String? ?? '';

    final senderLocation = senderInfo['address'] ?? 'ไม่ระบุ';
    final senderName = senderInfo['name'] ?? 'ไม่ระระบุ';
    final senderPhone = senderInfo['phone'] ?? 'ไม่ระบุ';

    final recipientLocation = receiverInfo['address'] ?? 'ไม่ระบุ';
    final recipientName = receiverInfo['name'] ?? 'ไม่ระบุ';
    final recipientPhone = receiverInfo['phone'] ?? 'ไม่ระบุ';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              child: (imageUrl.isNotEmpty)
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error))
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(
                  icon: Icons.location_on,
                  color: Colors.red,
                  location: senderLocation,
                  person: 'ชื่อผู้ส่ง : $senderName',
                  phone: 'เบอร์โทร : $senderPhone',
                ),
                const SizedBox(height: 12),
                _buildLocationRow(
                  icon: Icons.location_on,
                  color: Colors.green,
                  location: recipientLocation,
                  person: 'ชื่อผู้รับ : $recipientName',
                  phone: 'เบอร์โทร : $recipientPhone',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 120,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailPage(packageId: packageId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDE428),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 0),
                        elevation: 0,
                      ),
                      child: const Text(
                        'รายละเอียด',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String location,
    required String person,
    required String phone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                person,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                phone,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.yellow.shade700,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'รายการสินค้าที่ต้องส่ง',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146),
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) return;
        switch (index) {
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MoreOptionsPage()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'ประวัติการส่งสินค้า',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'อื่นๆ'),
      ],
    );
  }
}

class CustomAppBarClipper extends CustomClipper<Path> {
  final double borderRadius;
  CustomAppBarClipper({this.borderRadius = 20.0});
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - borderRadius);
    path.quadraticBezierTo(0, size.height, borderRadius, size.height);
    path.lineTo(size.width - borderRadius, size.height);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - borderRadius,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}