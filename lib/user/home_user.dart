import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(),
            _buildButtonSection(context), // ส่ง context ไปที่ฟังก์ชันสร้างปุ่ม
            const SizedBox(height: 20),
            _buildAdCard(
              imageUrl:
                  'https://moviedelic.com/wp-content/uploads/2025/05/Mad-Unicornuniversal-base_na_01_zxx-1-e1748597704822.jpg', // Replace with your image URL

              title: 'TUNDER EXPRESS',
            ),

            const SizedBox(height: 20),

            _buildAdCard(
              imageUrl:
                  'https://img.youtube.com/vi/Tb_H0-BavZY/sddefault.jpg', // Replace with your image URL

              title: 'กว่าจะเป็น ‘สันติ’',
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ส่วนบนของหน้า
  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFEE146),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'สวัสดี Tester',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFA9A9A9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'หอพักอัจฉราแมนชั่น ตึกใหม่',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ส่วนของปุ่ม 3 ปุ่ม
  Widget _buildButtonSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(color: Color(0xFFFEE146)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context, // ส่ง context ไปที่ฟังก์ชันสร้างปุ่ม
                  text: 'ส่งสินค้า',
                  icon: Icons.delivery_dining,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  context, // ส่ง context ไปที่ฟังก์ชันสร้างปุ่ม
                  text: 'สินค้าที่กำลังส่ง',
                  icon: Icons.local_shipping,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: _buildReceivedButton(context),
          ), // ส่ง context ไปที่ฟังก์ชันสร้างปุ่ม
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มสำหรับ 'ส่งสินค้า' และ 'สินค้าที่กำลังส่ง'
  Widget _buildActionButton(
    BuildContext context, {
    required String text,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        // เพิ่มโค้ดสำหรับนำทางไปยังหน้าอื่นที่นี่
        if (text == 'ส่งสินค้า') {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const DeliveryPage()), // ใส่ชื่อหน้าปลายทางของคุณที่นี่
          // );
          print('กดปุ่ม ส่งสินค้า'); // ตัวอย่างการแสดงข้อความใน Console
        } else if (text == 'สินค้าที่กำลังส่ง') {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const InTransitPage()), // ใส่ชื่อหน้าปลายทางของคุณที่นี่
          // );
          print('กดปุ่ม สินค้าที่กำลังส่ง'); // ตัวอย่างการแสดงข้อความใน Console
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 40),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มสำหรับ 'สินค้าที่ต้องรับ'
  Widget _buildReceivedButton(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () {
          // เพิ่มโค้ดสำหรับนำทางไปยังหน้าอื่นที่นี่
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const ReceivedPage()), // ใส่ชื่อหน้าปลายทางของคุณที่นี่
          // );
          print('กดปุ่ม สินค้าที่ต้องรับ'); // ตัวอย่างการแสดงข้อความใน Console
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.blue[300], size: 40),
              const SizedBox(width: 10),
              const Text(
                'สินค้าที่ต้องรับ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ส่วนของการ์ดรูปภาพ
  Widget _buildAdCard({
    required String imageUrl,
    required String title,
    String? description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            ),
            if (description != null && description.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ส่วนเมนูด้านล่าง
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
