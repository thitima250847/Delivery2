import 'package:delivery/user/detail.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildCustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow.shade700, width: 1.5),
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
                  'ประวัติการส่งสินค้า',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ***** 1. แก้ไข Query: ดึงข้อมูลทั้งหมดของผู้ใช้ (ไม่ต้องกรอง status) *****
              stream: FirebaseFirestore.instance
                  .collection('packages')
                  .where('sender_user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีประวัติการส่งสินค้า'));
                }

                // ดึงข้อมูลทั้งหมด
                final allPackages = snapshot.data!.docs;

                // ***** 2. เพิ่มส่วนนี้: กรองข้อมูลในแอปเอง *****
                final completedPackages = allPackages.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // เอาเฉพาะรายการที่ status เป็น 'completed'
                  return data['status'] == 'completed';
                }).toList();
                // ****************************************

                if (completedPackages.isEmpty) {
                  return const Center(child: Text('ยังไม่มีประวัติการส่งสินค้า'));
                }

                // ***** 3. ใช้ completedPackages ที่กรองแล้วมาสร้าง ListView *****
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: completedPackages.length,
                  itemBuilder: (context, index) {
                    final packageData = completedPackages[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildHistoryCard(context, packageData: packageData),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // --- (Widget อื่นๆ ไม่มีการเปลี่ยนแปลง) ---
  Widget _buildHistoryCard(
    BuildContext context, {
    required Map<String, dynamic> packageData,
  }) {
    final senderInfo = packageData['sender_info'] as Map<String, dynamic>? ?? {};
    final receiverInfo = packageData['receiver_info'] as Map<String, dynamic>? ?? {};

    final senderLocation = senderInfo['address'] ?? 'ไม่ระบุที่อยู่ผู้ส่ง';
    final senderName = senderInfo['name'] ?? 'ไม่ระบุชื่อผู้ส่ง';
    final senderPhone = senderInfo['phone'] ?? 'ไม่มีเบอร์โทร';

    final recipientLocation = receiverInfo['address'] ?? 'ไม่ระบุที่อยู่ผู้รับ';
    final recipientName = receiverInfo['name'] ?? 'ไม่ระบุชื่อผู้รับ';
    final recipientPhone = receiverInfo['phone'] ?? 'ไม่มีเบอร์โทร';

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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 40,
              color: Colors.green.shade700,
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DetailPage(packageId: '',),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE428),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'รายละเอียด',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.black,
                          size: 16,
                        ),
                      ],
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

  PreferredSize _buildCustomAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(160),
      child: ClipPath(
        clipper: CustomAppBarClipper(borderRadius: 30.0),
        child: Container(
          color: const Color(0xFFFDE428),
          padding: const EdgeInsets.only(top: 45, left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'สวัสดี Tester',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'หอพักอัครฉัตรแมนชั่น ตึกใหม่',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146),
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryPage()),
            );
            break;
          case 1:
            // หน้าปัจจุบัน ไม่ต้องทำอะไร
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