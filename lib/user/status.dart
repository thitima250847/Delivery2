import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';

// vvv เปลี่ยนชื่อคลาสเป็น StatusScreen
class StatusScreen extends StatelessWidget {
  // vvv อัปเดต Constructor
  const StatusScreen({super.key});

  // กำหนดสีเหลืองหลักที่ใช้ในแอป
  static const Color primaryYellow = Color(0xFFFDE100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,

        // vvvv เพิ่มบรรทัดนี้เพื่อปรับความสูง vvvv
        toolbarHeight: 90.0, // (ค่าปกติคือ 56.0)
        // ^^^^ สามารถปรับตัวเลขนี้ได้ตามต้องการ ^^^^
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryPage()),
            );
          },
        ),
        title: const Text(
          "สถานะการจัดส่งสินค้า",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        // ... (ส่วน body, Column, Divider เหมือนเดิม) ...
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. บล็อกสถานะชิ้นแรก
              _buildDeliveryStatusCard(
                boxImageUrl: "https://i.imgur.com/g0P3Y8b.png", // รูปกล่องพัสดุ
                riderImageUrl: "https://i.imgur.com/gX3tYlI.png", // รูปคนขับ
                riderName: "Thitima",
                riderPhone: "065576****",
                riderPlate: "ขก8",
              ),

              // เส้นคั่นระหว่างรายการ
              const Divider(
                height: 40,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),

              // 2. บล็อกสถานะชิ้นที่สอง
              _buildDeliveryStatusCard(
                boxImageUrl:
                    "https://i.imgur.com/iELFk1s.png", // รูปกล่องเก็บของ
                riderImageUrl: "https://i.imgur.com/gX3tYlI.png", // รูปคนขับ
                riderName: "Sarayut",
                riderPhone: "081234****",
                riderPlate: "มค9",
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  /// --- WIDGET BUILDERS --- ///

  /// Widget สำหรับสร้าง 1 บล็อกสถานะการส่ง
  Widget _buildDeliveryStatusCard({
    required String boxImageUrl,
    required String riderImageUrl,
    required String riderName,
    required String riderPhone,
    required String riderPlate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. ตัวติดตามสถานะ (Stepper)
        _buildStepper(),
        const SizedBox(height: 24),

        // vvvv  2. "สินค้าที่จะส่ง" (เปลี่ยนเป็น Container) vvvv
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                // vvvv เปลี่ยนสีตรงนี้ครับ vvvv
                color: const Color(0xFFFFD900), // สี FFD900
                // ^^^^ ^^^^
                width: 1.5,
              ),
            ),
            child: const Text(
              "สินค้าที่จะส่ง",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFA6A000),
              ),
            ),
          ),
        ),

        // ^^^^ จบส่วนที่แก้ไข ^^^^
        const SizedBox(height: 16),

        // 3. รูปภาพสินค้า
        Center(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                boxImageUrl,
                width: 150,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 4. การ์ดข้อมูลไรเดอร์ (เหมือนเดิม)
        const Text(
          "ข้อมูลไรเดอร์ที่รับงาน",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(riderImageUrl),
              radius: 28,
            ),
            title: Text(
              "ชื่อ : $riderName",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "หมายเลขโทรศัพท์ : $riderPhone",
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  "หมายเลขทะเบียนรถ : $riderPlate",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ... (ส่วน _buildStepper, _buildStepItem, _buildStepConnector เหมือนเดิม) ...

  /// Widget สำหรับสร้างตัวติดตามสถานะ (Stepper)
  Widget _buildStepper() {
    // ใน UI จริง, คุณควรมีตัวแปร state เพื่อบอกว่าสถานะไหน active
    // แต่ในตัวอย่างนี้จะแสดงผลตามรูปที่ให้มา
    return Row(
      children: [
        _buildStepItem(
          Icons.hourglass_top_rounded,
          "รอไรเดอร์รับสินค้า",
          Colors.green,
        ),
        _buildStepConnector(),
        _buildStepItem(
          Icons.assignment_turned_in_outlined,
          "ไรเดอร์รับงาน",
          Colors.green,
        ),
        _buildStepConnector(),
        _buildStepItem(
          Icons.delivery_dining_outlined,
          "กำลังเดินทางส่งสินค้า",
          Colors.red,
        ),
        _buildStepConnector(),
        _buildStepItem(
          Icons.check_circle_outline_rounded,
          "ส่งสินค้าเสร็จสิ้น",
          Colors.green,
        ),
      ],
    );
  }

  /// Widget สำหรับสร้าง 1 ไอคอนใน Stepper
  Widget _buildStepItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 2),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Widget สำหรับสร้างเส้นเชื่อมระหว่าง Step
  Widget _buildStepConnector() {
    return Expanded(
      child: Column(
        children: [
          Container(height: 2, color: Colors.grey.shade400),
          const SizedBox(
            height: 42,
          ), // จัดตำแหน่งให้อยู่ตรงกลาง (SizedBox + Text)
        ],
      ),
    );
  }

  // ... (ส่วน _buildBottomNavigationBar เหมือนเดิม) ...
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146),
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryPage()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
            break;
          case 2:
            Navigator.push(
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
