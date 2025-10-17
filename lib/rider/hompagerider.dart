import 'package:flutter/material.dart';

// (คุณสามารถลบ main() และ MyApp() ออกได้ หากนำไปรวมกับโปรเจกต์เดิม)
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rider Home UI',
      theme: ThemeData(fontFamily: 'Prompt'),
      debugShowCheckedModeBanner: false,
      home: const RiderHomeScreen(),
    );
  }
}
// -----------------------------------------------------------------

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({Key? key}) : super(key: key);

  // กำหนดสีเหลืองหลักที่ใช้ในแอป
  static const Color primaryYellow = Color(0xFFFDE100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // พื้นหลังสีเทาอ่อน
      body: Column(
        children: [
          // 1. ส่วนหัวสีเหลือง
          _buildHeader(),

          // 2. ส่วนเนื้อหา (รายการสินค้า)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTitleButton(),
                  _buildOrderCard(context),
                  // สามารถเพิ่ม _buildOrderCard() อีกได้ที่นี่
                ],
              ),
            ),
          ),
        ],
      ),
      // 3. Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// --- WIDGET BUILDERS --- ///

  /// Widget สำหรับสร้างส่วนหัวสีเหลือง
  Widget _buildHeader() {
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
          // ข้อความ สวัสดี Tester
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "สวัสดี",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                "Tester",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          // ไอคอนโปรไฟล์
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 50),
          ),
        ],
      ),
    );
  }

  /// Widget สำหรับปุ่ม "รายการสินค้าที่ต้องไปส่ง"
  Widget _buildTitleButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFFFD900), // สีขอบเหลือง
          width: 1.5,
        ),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Widget สำหรับสร้างการ์ดรายการสินค้า
  Widget _buildOrderCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracking ID
            const Text(
              "Tracking ID\n#16623666",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.2, // ลดระยะห่างระหว่างบรรทัด
              ),
            ),
            const SizedBox(height: 16),
            // ข้อมูลและรูปภาพ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนข้อมูล (ซ้าย)
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
                      const SizedBox(height: 16),
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
                const SizedBox(width: 16),
                // ส่วนรูปภาพ (ขวา)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    "https://i.imgur.com/wY6p9h0.png", // Placeholder รูปส่งของ
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ปุ่มรับ Order
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
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
                    backgroundColor: primaryYellow,
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

  /// Helper Widget สำหรับแสดงข้อมูลที่อยู่ (ผู้ส่ง/ผู้รับ)
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
                "ชื่อผู้ส่ง : $name",
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

  /// Widget สำหรับสร้าง Bottom Navigation Bar
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black, // สีของไอเทมที่เลือก
      unselectedItemColor: primaryYellow, // สีของไอเทมที่ไม่ได้เลือก
      currentIndex: 0, // ตั้งค่าให้ "หน้าแรก" ถูกเลือกอยู่
      type: BottomNavigationBarType.fixed, // ให้แสดง label ตลอด
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: "หน้าแรก",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.exit_to_app_rounded),
          label: "ออกจากระบบ",
        ),
      ],
    );
  }
}
