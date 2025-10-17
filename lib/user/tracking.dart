import 'package:delivery/user/detail.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ดึงความสูงของ status bar ของเครื่อง
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: ClipPath(
          clipper: CustomAppBarClipper(borderRadius: 20.0),
          child: Container(
            color: const Color(0xFFFDE428),
            padding: EdgeInsets.only(top: statusBarHeight),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {},
                ),
                const Text(
                  'สินค้าที่กำลังจัดส่ง',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ✅ ไม่มี bottomNavigationBar แล้ว
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage('assets/map.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            buildTrackingCard(
              context,
              name: 'Thitima',
              phone: '065576****',
              licensePlate: 'บก8',
              currentStep: 2,
            ),
            const SizedBox(height: 20),
            buildTrackingCard(
              context,
              name: 'Thitima',
              phone: '065576****',
              licensePlate: 'บก8',
              currentStep: 0,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget buildTrackingCard(
    BuildContext context, {
    required String name,
    required String phone,
    required String licensePlate,
    required int currentStep,
  }) {
    const Color primaryColor = Color(0xFFFDE428);
    const Color textGreyColor = Color(0xFF8A8A8A);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ชื่อ : $name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'หมายเลขโทรศัพท์ : $phone',
                      style: const TextStyle(
                        color: textGreyColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'หมายเลขทะเบียนรถ : $licensePlate',
                      style: const TextStyle(
                        color: textGreyColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // (ลบ onPressed ที่ซ้อนกันออก)

                  Navigator.push(
                    context,
                    // (เพิ่ม ')' หลัง DetailPage() และย้าย ';' มาไว้ท้ายสุด)
                    MaterialPageRoute(builder: (context) => const DetailPage()),
                  );

                  print(
                    'กดปุ่ม รายละเอียด',
                  ); // (เอาบรรทัดนี้ออกเมื่อใช้ Navigator)
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
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
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildStatusStepper(currentStep: currentStep),
        ],
      ),
    );
  }

  Widget buildStatusStepper({required int currentStep}) {
    const double iconSize = 24.0;
    const double circleRadius = 20.0;
    const Color activeColor = Color(0xFFFDE428);

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              height: 4.0,
              color: activeColor,
              margin: const EdgeInsets.symmetric(
                horizontal: circleRadius * 1.5,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildStepItem(
              title: 'รอไรเดอร์รับสินค้า',
              iconData: Icons.hourglass_empty,
              stepIndex: 0,
              currentStep: currentStep,
              iconSize: iconSize,
              circleRadius: circleRadius,
            ),
            buildStepItem(
              title: 'ไรเดอร์รับงาน',
              iconData: Icons.receipt_long,
              stepIndex: 1,
              currentStep: currentStep,
              iconSize: iconSize,
              circleRadius: circleRadius,
            ),
            buildStepItem(
              title: 'กำลังเดินทางส่งสินค้า',
              iconData: Icons.delivery_dining,
              stepIndex: 2,
              currentStep: currentStep,
              iconSize: iconSize,
              circleRadius: circleRadius,
            ),
            buildStepItem(
              title: 'ส่งสินค้าเสร็จสิ้น',
              iconData: Icons.check,
              stepIndex: 3,
              currentStep: currentStep,
              iconSize: iconSize,
              circleRadius: circleRadius,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildStepItem({
    required String title,
    required IconData iconData,
    required int stepIndex,
    required int currentStep,
    required double iconSize,
    required double circleRadius,
  }) {
    Color iconColor = Colors.grey.shade400;
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.grey;

    if (stepIndex < currentStep) {
      iconColor = Colors.green;
      borderColor = Colors.green;
    } else if (stepIndex == currentStep) {
      iconColor = Colors.orange;
      borderColor = const Color(0xFFFDE428);
    }

    return Column(
      children: [
        Container(
          width: circleRadius * 2,
          height: circleRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 3),
          ),
          child: Icon(iconData, size: iconSize, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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
            // หน้าปัจจุบัน ไม่ต้องทำอะไร
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
