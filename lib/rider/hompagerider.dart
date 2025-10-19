import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({Key? key}) : super(key: key);

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  static const Color primaryYellow = Color(0xFFFDE100);

  // --- ฟังก์ชันสำหรับรับ Order ---
  Future<void> _acceptOrder(String packageId) async {
    try {
      final riderId = FirebaseAuth.instance.currentUser?.uid;
      if (riderId == null) {
        throw Exception("ไม่สามารถระบุตัวตนไรเดอร์ได้");
      }

      // อัปเดตสถานะของ package เป็น 'accepted' และเพิ่ม rider_id
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการรับงาน: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              children: [
                _buildTitleButton(),
                // --- ส่วนแสดงผลรายการสินค้าแบบ Real-time ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    // ดึงข้อมูลจาก collection 'packages' ที่ status เป็น 'pending'
                    stream: FirebaseFirestore.instance
                        .collection('packages')
                        .where('status', isEqualTo: 'pending')
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
                        return const Center(
                            child: Text('ยังไม่มีรายการสินค้าให้จัดส่ง'));
                      }

                      // ถ้ามีข้อมูล ให้แสดงผลด้วย ListView
                      final packages = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                          final packageDoc = packages[index];
                          final packageData =
                              packageDoc.data() as Map<String, dynamic>;
                          // ส่งข้อมูลเข้าไปใน Card
                          return _buildOrderCard(
                              context, packageDoc.id, packageData);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// --- WIDGET BUILDERS (เหมือนเดิม แต่มีการรับค่าเพิ่ม) --- ///

  Widget _buildHeader() {
    // โค้ดส่วนนี้เหมือนเดิม ไม่มีการเปลี่ยนแปลง
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: primaryYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("สวัสดี", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Tester", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: Colors.grey[600], shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 50),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleButton() {
    // โค้ดส่วนนี้เหมือนเดิม ไม่มีการเปลี่ยนแปลง
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

  // --- แก้ไข _buildOrderCard ให้รับข้อมูลแบบไดนามิก ---
  Widget _buildOrderCard(
      BuildContext context, String docId, Map<String, dynamic> package) {
    // ดึงข้อมูลจาก Map
    final senderInfo = package['sender_info'] as Map<String, dynamic>;
    final receiverInfo = package['receiver_info'] as Map<String, dynamic>;
    final imageUrl = package['proof_image_url'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดง ID ของ Order (ใช้ ID ของ document)
            Text(
              "Tracking ID\n#${docId.substring(0, 8)}", // แสดง ID 8 ตัวแรก
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // --- แสดงข้อมูลผู้ส่ง (จาก Firestore) ---
                      _buildAddressInfo(
                        icon: Icons.location_on,
                        iconColor: Colors.red,
                        title: senderInfo['address'] ?? 'ไม่ระบุที่อยู่',
                        name: senderInfo['name'] ?? 'ผู้ส่ง',
                        phone: senderInfo['phone'] ?? 'ไม่มีเบอร์',
                        labelPrefix: "ชื่อผู้ส่ง",
                      ),
                      const SizedBox(height: 16),
                      // --- แสดงข้อมูลผู้รับ (จาก Firestore) ---
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
                  // --- แสดงรูปภาพ (จาก Firestore) ---
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          // แสดง loading ขณะโหลดรูป
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                        child: CircularProgressIndicator()));
                          },
                          // แสดง Icon กรณีรูปโหลดไม่ได้
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported));
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  // --- เมื่อกดปุ่ม ให้เรียกฟังก์ชัน _acceptOrder ---
                  onPressed: () => _acceptOrder(docId),
                  icon: const Icon(Icons.inventory_2_outlined, color: Colors.black),
                  label: const Text("รับ Order", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- แก้ไข _buildAddressInfo ให้ยืดหยุ่นขึ้น ---
  Widget _buildAddressInfo({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String phone,
    required String labelPrefix, // "ชื่อผู้ส่ง" หรือ "ชื่อผู้รับ"
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("$labelPrefix : $name", style: const TextStyle(fontSize: 13, color: Colors.black54)),
              Text("เบอร์โทรศัพท์ : $phone", style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    // โค้ดส่วนนี้เหมือนเดิม ไม่มีการเปลี่ยนแปลง
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: primaryYellow,
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "หน้าแรก"),
        BottomNavigationBarItem(icon: Icon(Icons.exit_to_app_rounded), label: "ออกจากระบบ"),
      ],
    );
  }
}