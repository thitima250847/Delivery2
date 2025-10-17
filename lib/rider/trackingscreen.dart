import 'package:flutter/material.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

// 2. นี่คือคลาส State (เมธอด helper ทั้งหมดต้องอยู่ในนี้)
class _TrackingScreenState extends State<TrackingScreen> {
  // กำหนดสีเหลืองหลักที่ใช้ในแอป
  static const Color primaryYellow = Color(0xFFFDE100);

  // ตัวแปรสำหรับเก็บสถานะแท็บที่เลือก (0 = สถานะกำลังส่ง, 1 = นำส่งสินค้าแล้ว)
  int _selectedTabIndex = 0; // <--- ตัวแปรนี้อยู่ "ใน" State

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // พื้นหลังสีเทาอ่อน
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. ส่วนหัวสีเหลือง + Stepper
            _buildHeader(), // <--- เรียกใช้เมธอด
            const SizedBox(height: 24.0), // (ปรับตัวเลข 24.0 ได้ตามชอบ)
            // 3. แผนที่
            _buildMap(),
            const SizedBox(height: 16),

            // 4. แท็บเลือกสถานะ
            _buildTabBar(),
            const SizedBox(height: 16),

            // 5. เนื้อหาตามแท็บที่เลือก
            _buildTabContent(),

            // 6. ปุ่ม "ข้อมูลสินค้า"
            _buildTitleButton("ข้อมูลสินค้า"),
            const SizedBox(height: 20),

            // 7. การ์ดข้อมูลสินค้า
            _buildProductCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // vvvv เมธอด Helper ทั้งหมดต้องอยู่ "ภายใน" คลาส _TrackingScreenState vvvv

  /// --- WIDGET BUILDERS --- ///

  /// Widget สำหรับสร้างส่วนหัวสีเหลือง + Stepper
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
      decoration: const BoxDecoration(color: primaryYellow),
      child: Row(
        children: [
          _buildStepItem(
            Icons.hourglass_top_rounded,
            "รอไรเดอร์รับสินค้า",
            true,
          ),
          _buildStepConnector(),
          _buildStepItem(
            Icons.assignment_turned_in_outlined,
            "ไรเดอร์รับงาน",
            true,
          ),
          _buildStepConnector(),
          _buildStepItem(
            Icons.delivery_dining_outlined,
            "กำลังเดินทางส่งสินค้า",
            true,
            isCurrent: true,
          ),
          _buildStepConnector(),
          _buildStepItem(
            Icons.check_circle_outline_rounded,
            "ส่งสินค้าเสร็จสิ้น",
            false,
          ),
        ],
      ),
    );
  }

  /// Widget สำหรับสร้าง 1 ไอคอนใน Stepper
  Widget _buildStepItem(
    IconData icon,
    String label,
    bool isActive, {
    bool isCurrent = false,
  }) {
    final Color color = isActive
        ? (isCurrent ? Colors.red : Colors.green)
        : Colors.grey;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, // วงกลมสีขาว
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black, // สีตัวอักษร
          ),
        ),
      ],
    );
  }

  /// Widget สำหรับสร้างเส้นเชื่อมระหว่าง Step
  Widget _buildStepConnector() {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 4, // หนาขึ้น
            color: Colors.white, // เส้นสีขาว
          ),
          const SizedBox(height: 42), // จัดตำแหน่ง
        ],
      ),
    );
  }

  /// Widget สำหรับปุ่มไตเติ้ล (ใช้ซ้ำ)
  Widget _buildTitleButton(String label) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 20, 176, 18),
          fontSize: 16,
        ),
      ),
    );
  }

  /// Widget สำหรับแสดงแผนที่
  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Image.network(
          "https://i.imgur.com/3Z0NpyA.png", // Placeholder รูปแผนที่
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Widget สำหรับสร้างแท็บ
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTabItem("สถานะกำลังส่ง", 0),
          const SizedBox(width: 10),
          _buildTabItem("นำส่งสินค้าแล้ว", 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // นี่คือฟังก์ชันที่ทำให้ "แดง" ถ้าอยู่ผิดที่
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // // นี่คือตัวแปรที่ทำให้ "แดง" ถ้าอยู่ผิดที่
            // color: _selectedTabIndex == index
            //     ? primaryYellow.withOpacity(0.7)
            //     : Colors.white,
            // borderRadius: BorderRadius.circular(10.0),
            // border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,

              // vvvv ปรับสีที่บรรทัดนี้ครับ vvvv
              color: Color(0xFF0FC964),
              // ^^^^ ^^^^
            ),
          ),
        ),
      ),
    );
  }

  /// Widget สำหรับแสดงเนื้อหาของแท็บ
  Widget _buildTabContent() {
    // นี่คือตัวแปรที่ทำให้ "แดง" ถ้าอยู่ผิดที่
    if (_selectedTabIndex == 0) {
      // --- เนื้อหาแท็บ "สถานะกำลังส่ง" ---
      return Column(
        children: [
          _buildPhotoUploaders(),
          const SizedBox(height: 16),
          _buildAddressCard(),
        ],
      );
    } else {
      // --- เนื้อหาแท็บ "นำส่งสินค้าแล้ว" ---
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text(
          "ยังไม่มีข้อมูลการนำส่งสินค้า",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
  }

  /// Widget สำหรับช่องอัปโหลดรูป
  Widget _buildPhotoUploaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildPhotoPlaceholder(),
          const SizedBox(width: 10),
          _buildPhotoPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.grey[400],
          size: 40,
        ),
      ),
    );
  }

  /// Widget สำหรับการ์ดข้อมูลที่อยู่
  Widget _buildAddressCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // ไอคอนไรเดอร์
            Image.network(
              "https://i.imgur.com/v8SjA9H.png", // (ใช้รูป Shiba แทน)
              width: 60,
              height: 60,
            ),
            const SizedBox(width: 16),
            // รายละเอียดที่อยู่
            Expanded(
              child: Column(
                children: [
                  _buildAddressInfo(
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    title: "คณะวิทยาการสารสนเทศ",
                    name: "Thitima",
                    phone: "0655764805",
                  ),
                  const SizedBox(height: 12),
                  _buildAddressInfo(
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    title: "หอพักเรืองรองริเวอร์วิว",
                    name: "Kanokwan Laptawee",
                    phone: "0967654321",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper Widget สำหรับแสดงข้อมูลที่อยู่ (คัดลอกจาก RiderHomeScreen)
  Widget _buildAddressInfo({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String phone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                "ชื่อผู้รับ : $name",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "เบอร์โทรศัพท์ : $phone",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget สำหรับการ์ดข้อมูลสินค้า
  Widget _buildProductCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // รูปสินค้า
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                "https://i.imgur.com/kS9YnSg.png", // Placeholder รูปเสื้อ
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // รายละเอียดสินค้า
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "รายละเอียดสินค้า:",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "เสื้อยืดแขนยาวสีดำ",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ^^^^ นี่คือปีกกาปิดของคลาส _TrackingScreenState ตรวจสอบว่าเมธอดทั้งหมดอยู่ "ก่อน" ปีกกานี้ ^^^^
}
