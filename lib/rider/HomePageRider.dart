import 'package:delivery/rider/orderMaps.dart';
import 'package:delivery/user/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ต้องมีการ import หน้า TrackingScreen เข้ามา เพื่อนำทางไปหน้าติดตามงาน
import 'trackingscreen.dart'; // ตรวจสอบ path ของไฟล์นี้ให้ถูกต้อง

// เปลี่ยนจาก StatelessWidget เป็น StatefulWidget เพื่อให้มี StreamBuilder ได้
class HomePageRider extends StatefulWidget {
  const HomePageRider({super.key, this.name = 'Tester'});
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

  // เพิ่มตัวแปรเพื่อเก็บ ID งานค้าง (ถ้ามี)
  String? _ongoingPackageId;

  @override
  void initState() {
    super.initState();
    // เพิ่ม: ตรวจสอบงานค้างทันทีที่เข้าสู่หน้า
    _checkOngoingTaskAndNavigate();
  }

  // เพิ่ม: ฟังก์ชันตรวจสอบงานค้างและนำทางไปหน้าติดตามงาน
  Future<void> _checkOngoingTaskAndNavigate() async {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId == null) return;

    // ค้นหางานที่มีสถานะ 'accepted' (รับงานแล้ว) หรือ 'on_delivery' (กำลังเดินทาง)
    final ongoingPackages = await FirebaseFirestore.instance
        .collection('packages')
        .where('rider_id', isEqualTo: riderId)
        .where('status', whereIn: ['accepted', 'on_delivery'])
        .limit(1)
        .get();

    if (ongoingPackages.docs.isNotEmpty) {
      final packageId = ongoingPackages.docs.first.id;
      _ongoingPackageId = packageId; // เก็บ ID งานค้างไว้

      // นำทางไปหน้า TrackingScreen โดยล้างหน้า Home ออกจาก Stack (pushReplacement)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TrackingScreen(packageId: packageId),
          ),
        );
      }
    } else {
      _ongoingPackageId = null; // ยืนยันว่าไม่มีงานค้าง
    }
  }

  // =================================================================
  // === ฟังก์ชันสำหรับรับ Order (แก้ไขใหม่ทั้งหมดโดยใช้ Transaction) ===
  // =================================================================
  Future<void> _acceptOrder(String packageId) async {
    try {
      final riderId = FirebaseAuth.instance.currentUser?.uid;
      if (riderId == null) {
        throw Exception("ไม่สามารถระบุตัวตนไรเดอร์ได้");
      }

      // 1. ตรวจสอบเบื้องต้นว่าไรเดอร์คนนี้มีงานอื่นค้างอยู่หรือไม่ (ทำนอก Transaction ได้)
      final ongoingPackagesCheck = await FirebaseFirestore.instance
          .collection('packages')
          .where('rider_id', isEqualTo: riderId)
          .where('status', whereIn: ['accepted', 'on_delivery'])
          .limit(1)
          .get();

      if (ongoingPackagesCheck.docs.isNotEmpty) {
        throw Exception(
          "คุณมีงานที่กำลังดำเนินการอยู่แล้ว กรุณาส่งงานปัจจุบันให้เสร็จก่อนรับงานใหม่",
        );
      }

      // 2. ดึงข้อมูลป้ายทะเบียน (ทำนอก Transaction ได้)
      final riderDoc =
          await FirebaseFirestore.instance.collection('riders').doc(riderId).get();
      if (!riderDoc.exists) {
        throw Exception('ไม่พบโปรไฟล์ของไรเดอร์');
      }
      final riderPlate = riderDoc.data()?['license_plate'] ?? 'N/A';

      // 3. เริ่ม Transaction เพื่อรับงานอย่างปลอดภัย
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final packageRef =
            FirebaseFirestore.instance.collection('packages').doc(packageId);
        
        // อ่านข้อมูลล่าสุดของออเดอร์ภายใน Transaction
        final packageSnapshot = await transaction.get(packageRef);

        if (!packageSnapshot.exists) {
          throw Exception("ไม่พบออเดอร์นี้ในระบบ อาจถูกลบไปแล้ว");
        }

        // *** จุดตรวจสอบที่สำคัญที่สุด ***
        // เช็คว่าสถานะยังเป็น 'pending' หรือไม่
        if (packageSnapshot.data()?['status'] != 'pending') {
          // ถ้าไม่ใช่ แสดงว่ามีคนอื่นตัดหน้าไปแล้ว
          throw Exception("ออเดอร์นี้ถูกรับไปแล้ว");
        }

        // ถ้ายังเป็น 'pending' อยู่ ให้อัปเดตข้อมูลภายใน Transaction นี้เท่านั้น
        transaction.update(packageRef, {
          'status': 'accepted',
          'rider_id': riderId,
          'rider_plate': riderPlate,
        });
      });

      // 4. ถ้า Transaction สำเร็จ (ไม่เกิด Exception) แสดงว่ารับงานได้
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รับงานสำเร็จ! กำลังนำทางไปหน้าติดตาม'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TrackingScreen(packageId: packageId),
          ),
        );
      }
    } catch (e) {
      // Catch จะดักจับ Exception ทั้งหมด รวมถึง "ออเดอร์นี้ถูกรับไปแล้ว"
      if (mounted) {
        final errorMessage = e.toString().contains("Exception:")
            ? e.toString().replaceFirst("Exception: ", "")
            : 'เกิดข้อผิดพลาดในการรับงาน: $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // ใช้สีให้เข้ากัน
      body: Column(
        children: [
          _buildHeader(),
          _buildTitleButton(),
          // --- StreamBuilder: ส่วนแสดงผลรายการสินค้า ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Query ที่ถูกต้อง: ดึงรายการที่สถานะเป็น 'pending'
              stream: FirebaseFirestore.instance
                  .collection('packages')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
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

  /// --- WIDGET BUILDERS (มีการเพิ่มปุ่มงานค้างใน Header) ---

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
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
          // *** ส่วนที่เพิ่ม: ปุ่มสำหรับดูงานที่รับค้างไว้ ***
          if (_ongoingPackageId != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // นำทางไปหน้า TrackingScreen ของงานที่ค้างไว้
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrackingScreen(packageId: _ongoingPackageId!),
                    ),
                  );
                },
                icon: const Icon(Icons.delivery_dining, color: Colors.white),
                label: const Text(
                  "ดูรายการที่ต้องส่ง (งานค้าง)",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTextBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          // **********************************************
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
    final packageDescription =
        package['package_description'] as String? ?? 'ไม่มีรายละเอียด';

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
            const Divider(height: 24),
            Text.rich(
              TextSpan(
                text: 'ชื่อสินค้า: ',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                children: [
                  TextSpan(
                    text: packageDescription,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderMapsPage(packageId: docId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, color: Colors.white),
                  label: const Text(
                    "ดูแผนที่",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                const SizedBox(width: 8),
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
              onTap: () {
                // อยู่หน้าแรกอยู่แล้ว ไม่ต้องทำอะไร
              },
            ),
            _BottomItem(
              icon: Icons.exit_to_app_rounded,
              label: 'ออกจากระบบ',
              color: kYellow,
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
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