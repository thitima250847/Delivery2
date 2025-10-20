import 'package:delivery/rider/trackingscreen.dart';
import 'package:delivery/user/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// เปลี่ยนจาก StatelessWidget เป็น StatefulWidget เพื่อให้มี StreamBuilder ได้
class HomePageRider extends StatefulWidget {
  const HomePageRider({Key? key, this.name = 'Tester'}) : super(key: key);
  final String name;

  @override
  State<HomePageRider> createState() => _HomePageRiderState();
}

// นำโค้ด _RiderHomeScreenState มาใช้ที่นี่ และเพิ่ม UI ของ HomePageRider
class _HomePageRiderState extends State<HomePageRider> {
  static const Color primaryYellow = Color(0xFFFDE100);
  static const kYellow = Color(0xFFF0DB0C); // ใช้สีให้เข้ากัน
  static const kTextBlack = Color(0xFF111111);
  static const kGreyIcon = Color(0xFF9E9E9E);

  // --- ฟังก์ชันสำหรับรับ Order ---
Future<void> _acceptOrder(String packageId) async {
  try {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId == null) {
      throw Exception("ไม่สามารถระบุตัวตนไรเดอร์ได้");
    }

    // --- (1) ตรวจสอบว่า Rider มีงานที่กำลังทำอยู่หรือไม่ ---
    // ค้นหางานที่มีสถานะ 'accepted' (รับงานแล้ว) หรือ 'on_delivery' 
    // และมี rider_id เป็นของ Rider คนปัจจุบัน
    final ongoingPackages = await FirebaseFirestore.instance
        .collection('packages')
        .where('rider_id', isEqualTo: riderId)
        .where('status', whereIn: ['accepted', 'on_delivery'])
        .limit(1)
        .get();

    if (ongoingPackages.docs.isNotEmpty) {
      throw Exception("คุณมีงานที่กำลังดำเนินการอยู่แล้ว กรุณาส่งงานปัจจุบันให้เสร็จก่อนรับงานใหม่");
    }
    // --------------------------------------------------------

    // (2) ถ้าไม่มีงานค้าง ให้ดำเนินการรับงาน
    await FirebaseFirestore.instance
        .collection('packages')
        .doc(packageId)
        .update({
      'status': 'accepted', 
      'rider_id': riderId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รับงานสำเร็จ!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      // แสดงข้อความที่ถูกกำหนดเอง (ถ้าเป็น String)
      final errorMessage = e.toString().contains("Exception:") 
          ? e.toString().replaceFirst("Exception: ", "")
          : 'เกิดข้อผิดพลาดในการรับงาน: $e';
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    print(">>> RIDER HOME SCREEN BUILD STARTED"); // โค้ด Debug
    return Scaffold(
      backgroundColor: Colors.grey[200], // ใช้สีให้เข้ากัน
      body: Column(
        children: [
          _buildHeader(),
          _buildTitleButton(),
          _buildNavigateButton(),
          // --- StreamBuilder: ส่วนแสดงผลรายการสินค้า ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Query ที่ถูกต้อง: ดึงรายการที่สถานะเป็น 'pending'
              stream: FirebaseFirestore.instance
                  .collection('packages')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                // โค้ด Debug (สำคัญมาก)
                print("--- StreamBuilder Rebuild ---");
                if (snapshot.hasError) {
                  print(">>> SNAPSHOT ERROR: ${snapshot.error}");
                }
                if (snapshot.hasData) {
                  print(
                    ">>> SNAPSHOT HAS DATA: Found ${snapshot.data!.docs.length} documents",
                  );
                } else {
                  print(">>> SNAPSHOT HAS NO DATA YET");
                }
                print("----------------------------");
                // สิ้นสุดโค้ด Debug

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีรายการสินค้าให้จัดส่ง'),
                  );
                }

                final packages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final packageDoc = packages[index];
                    final packageData =
                        packageDoc.data() as Map<String, dynamic>;
                    return _buildOrderCard(context, packageDoc.id, packageData);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: kYellow, // ใช้ kYellow จาก HomePageRider
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "สวัสดี",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextBlack,
                ),
              ),
              Text(
                widget.name, // ใช้ widget.name ที่ส่งมาจาก Login
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: kTextBlack,
                ),
              ),
            ],
          ),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: kGreyIcon,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 50),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFFFD900), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        "รายการสินค้าที่ต้องไปส่ง",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> package,
  ) {
    final senderInfo = package['sender_info'] as Map<String, dynamic>? ?? {};
    final receiverInfo =
        package['receiver_info'] as Map<String, dynamic>? ?? {};
    final imageUrl = package['proof_image_url'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tracking ID\n#${docId.substring(0, 8)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildAddressInfo(
                        icon: Icons.location_on,
                        iconColor: Colors.red,
                        title: senderInfo['address'] ?? 'ไม่ระบุที่อยู่',
                        name: senderInfo['name'] ?? 'ผู้ส่ง',
                        phone: senderInfo['phone'] ?? 'ไม่มีเบอร์',
                        labelPrefix: "ชื่อผู้ส่ง",
                      ),
                      const SizedBox(height: 16),
                      _buildAddressInfo(
                        icon: Icons.location_on,
                        iconColor: Colors.green,
                        title: receiverInfo['address'] ?? 'ไม่ระบุที่อยู่',
                        name: receiverInfo['name'] ?? 'ผู้รับ',
                        phone: receiverInfo['phone'] ?? 'ไม่มีเบอร์',
                        labelPrefix: "ชื่อผู้รับ",
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _acceptOrder(docId),
                  icon: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.black,
                  ),
                  label: const Text(
                    "รับ Order",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String phone,
    required String labelPrefix,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "$labelPrefix : $name",
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                "เบอร์โทรศัพท์ : $phone",
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomItem(
              icon: Icons.home_filled,
              label: 'หน้าแรก',
              color: Colors.black,
              onTap: () {},
            ),
            _BottomItem(
              icon: Icons.exit_to_app_rounded,
              label: 'ออกจากระบบ',
              color: kYellow,
              onTap: () {
                // ออกจากระบบ -> กลับไปหน้า Login และล้างเส้นทางเก่า
                FirebaseAuth.instance.signOut(); // ต้อง signOut
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(), // กลับไปหน้า Login
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- ฟังก์ชันสำหรับปุ่มใหม่ที่จะเพิ่ม ---
  Widget _buildNavigateButton() {
    return Padding(
      // เพิ่มระยะห่างเล็กน้อย
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      child: ElevatedButton(
        onPressed: () {
          // ใส่โค้ดสำหรับการเปลี่ยนหน้า_ที่นี่
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrackingScreen(),
            ), // <--- ไปยังหน้าที่คุณต้องการ
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow, // ใช้สีเหลืองจากธีม
          foregroundColor: kTextBlack, // ใช้สีดำจากธีม
          // ทำให้ปุ่มเต็มความกว้าง
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 2,
        ),
        child: const Text(
          'สถานะการส่ง', // <--- เปลี่ยนข้อความตามต้องการ
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ไอเท็มแถบล่าง
class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
