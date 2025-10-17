import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          _buildCustomAppBar(),
          Padding(
            padding: const EdgeInsets.only(top: 180.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 130.0),
              // --- vvv แก้ไขตรงนี้ vvv ---
              // ครอบ Column ด้วย Padding เพื่อเพิ่มระยะห่างซ้าย-ขวา
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildContentTitle(),
                    const SizedBox(height: 24),
                    _buildDeliveryCard(
                      senderLocation: 'หอพักอัครฉัตรแมนชั่น ตึกใหม่',
                      senderName: 'sathima kanlayasai',
                      recipientLocation: 'คณะวิทยาการสารสนเทศ',
                      recipientName: 'Soduku',
                    ),
                    const SizedBox(height: 16),
                    _buildDeliveryCard(
                      senderLocation: 'หอพักอัครฉัตรแมนชั่น ตึกใหม่',
                      senderName: 'sathima kanlayasai',
                      recipientLocation: 'คณะวิทยาการสารสนเทศ',
                      recipientName: 'Soduku',
                    ),
                  ],
                ),
              ),
              // --- ^^^ ^^^ ---
            ),
          ),
          Positioned(
            top: 150,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      label: 'ส่งสินค้า',
                      icon: Icons.send_rounded,
                      iconColor: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      label: 'สินค้าที่กำลังส่ง',
                      icon: Icons.local_shipping,
                      iconColor: Colors.orange.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  label: 'สินค้าที่ต้องรับ',
                  icon: Icons.inventory_2,
                  iconColor: Colors.green.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildCustomAppBar() {
    return ClipPath(
      child: Container(
        height: 280,
        width: double.infinity,
        color: const Color(0xFFFEE146),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'สวัสดี Tester',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA9A9A9),
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
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(icon, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildContentTitle() {
    return Container(
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
          'รายการสินค้าที่ต้องรับ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard({
    required String senderLocation,
    required String senderName,
    required String recipientLocation,
    required String recipientName,
  }) {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16), // ลบออก
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delivery_dining,
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
                ),
                const SizedBox(height: 12),
                _buildLocationRow(
                  icon: Icons.location_on,
                  color: Colors.green,
                  location: recipientLocation,
                  person: 'ชื่อผู้รับ : $recipientName',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {},
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
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildBottomNavigationBar(BuildContext context) {
  return BottomNavigationBar(
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xFFFEE146),
    unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
    currentIndex: 1, // หน้านี้คือ index 1 (ประวัติ)
    onTap: (index) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
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
