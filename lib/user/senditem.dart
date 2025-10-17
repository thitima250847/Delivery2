import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';

class SendItemPage extends StatelessWidget {
  const SendItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFEE146);
    const Color greenColor = Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // สีพื้นหลังเทาอ่อน
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios, color: Colors.black),
        title: const Text(
          'ส่งสินค้า',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.15),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- การ์ดข้อมูลผู้ใช้ ---
            _buildUserInfoCard(),
            const SizedBox(height: 24),

            // --- ปุ่ม "แบบฟอร์มข้อมูลสินค้าที่จะส่ง" ---
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Center(
                child: Text(
                  'แบบฟอร์มข้อมูลสินค้าที่จะส่ง',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- พื้นที่อัปโหลดรูปภาพ ---
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 60,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // --- ปุ่มอัปโหลด/ถ่ายรูป ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageActionButton(
                  label: 'อัปโหลดรูปสินค้า',
                  icon: Icons.add_photo_alternate_outlined,
                  color: primaryColor,
                ),
                _buildImageActionButton(
                  label: 'ถ่ายรูปสินค้า',
                  icon: Icons.camera_alt_outlined,
                  color: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- TextField รายละเอียดสินค้า ---
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'รายละเอียดสินค้า :',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- ปุ่ม "เพิ่ม" ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'เพิ่ม',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // --- ฟังก์ชันสำหรับสร้างการ์ดข้อมูลผู้ใช้ ---
  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey,
            // child: Image.asset('assets/your_profile_pic.png'), // <-- ใส่รูปโปรไฟล์ของคุณที่นี่
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ชื่อ', 'ตัวดี'),
                const SizedBox(height: 4),
                _buildInfoRow('หมายเลขโทรศัพท์', '0987490007'),
                const SizedBox(height: 4),
                _buildInfoRow('ที่อยู่', 'หอพักกรุุหตาม'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ฟังก์ชันย่อยสำหรับแสดงข้อมูลใน Card ---
  Widget _buildInfoRow(String label, String value) {
    return Text.rich(
      TextSpan(
        text: '$label : ',
        style: TextStyle(color: Colors.grey.shade600),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // --- ฟังก์ชันสำหรับสร้างปุ่ม อัปโหลด/ถ่ายรูป ---
  Widget _buildImageActionButton({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }

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
