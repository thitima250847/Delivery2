import 'package:delivery/user/chagepassword.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/login.dart';
import 'package:delivery/user/profileuser.dart';
import 'package:flutter/material.dart';

class MoreOptionsPage extends StatelessWidget {
  const MoreOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildCustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // vvvv 2. ส่ง context เข้าไป vvvv
            _buildOptionButton(context, label: 'ข้อมูลส่วนตัว'),
            const SizedBox(height: 16),
            _buildOptionButton(context, label: 'เปลี่ยนรหัสผ่าน'),
            const SizedBox(height: 16),
            _buildOptionButton(context, label: 'ออกจากระบบ'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSize _buildCustomAppBar() {
    // ... (โค้ดส่วน AppBar เหมือนเดิม) ...
    return PreferredSize(
      preferredSize: const Size.fromHeight(170),
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
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
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
            ],
          ),
        ),
      ),
    );
  }

  // vvvv 3. แก้ไขฟังก์ชันนี้ (เพิ่ม context และ onTap logic) vvvv
  Widget _buildOptionButton(BuildContext context, {required String label}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // vvvv เพิ่ม Logic การนำทางที่นี่ vvvv
            if (label == 'แก้ไขข้อมูลส่วนตัว') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
              print('กดปุ่ม: $label');
            } else if (label == 'เปลี่ยนรหัสผ่าน') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
              print('กดปุ่ม: $label');
            } else if (label == 'ออกจากระบบ') {
              // (ตัวอย่างการ Logout กลับไปหน้า Login)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false, // ลบทุกหน้าก่อนหน้า
              );
              print('กดปุ่ม: $label');
            }
            // ^^^^ ^^^^
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // (ฟังก์ชัน _buildBottomNavigationBar เหมือนเดิม)
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146),
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            // (ใช้ pushReplacement เพื่อไม่ให้หน้าซ้อนกัน)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryPage()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
            break;
          case 2:
            // (ถ้าอยู่ที่หน้า "อื่นๆ" อยู่แล้ว ไม่ต้องทำอะไร)
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => const MoreOptionsPage()),
            // );
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

// (คลาส CustomAppBarClipper เหมือนเดิม)
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
