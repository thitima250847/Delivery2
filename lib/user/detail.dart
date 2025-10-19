import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart' hide CustomAppBarClipper;
import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  // สีเหลืองหลัก (เผื่อใช้)
  static const Color primaryYellow = Color(0xFFFDE428);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // สีพื้นหลังเทาอ่อน
      appBar: _buildCustomAppBar(context), // <--- ใช้ AppBar ที่แก้ไขแล้ว
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // การ์ดสินค้าใบที่ 1
            _buildDetailCard(
              trackingId: '#16623666',
              sender: 'XXX',
              recipientName: 'พิ๊ฟิ',
              recipientAddress:
                  '999 หมู่ 10 อ.เมืองหนึ่ง ต.หนึ่งแห่ง จ.มหาสารคาม 525456',
              recipientPhone: '0899999999',
              imagePlaceholderColor: Colors.grey.shade300,
              driverName: 'thitima',
              shippingDate: '21/9/2567 เวลา 10:00',
              deliveryDate: '21/9/2567 เวลา 12:00',
            ),
            const SizedBox(height: 16),
            // การ์ดสินค้าใบที่ 2
            _buildDetailCard(
              trackingId: '#16623666',
              sender: 'XXX',
              recipientName: 'พิ๊ฟิ',
              recipientAddress:
                  '999 หมู่ 10 อ.เมืองหนึ่ง ต.หนึ่งแห่ง จ.มหาสารคาม 525456',
              recipientPhone: '0899999999',
              imagePlaceholderColor: Colors.black26,
              driverName: 'thitima',
              shippingDate: '21/9/2567 เวลา 10:00',
              deliveryDate: '21/9/2567 เวลา 12:00',
            ),
          ],
        ),
      ),
      // --- พิจารณาว่าจะใส่ BottomNav หรือไม่ ---
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // --- Widget สำหรับสร้าง AppBar แบบโค้ง (แก้ไขแล้ว) ---
  PreferredSize _buildCustomAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return PreferredSize(
      preferredSize: const Size.fromHeight(100.0), // <-- ความสูง AppBar
      child: ClipPath(
        clipper: CustomAppBarClipper(borderRadius: 20.0),
        child: Container(
          // <-- ใช้ Container
          color: primaryYellow, // <-- กำหนดสีที่นี่
          padding: EdgeInsets.only(
            top: statusBarHeight, // <-- กันพื้นที่ Status Bar
          ),
          child: Center(
            // <-- ใช้ Center จัดกลางแนวตั้ง
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context); // <-- ใช้ pop()
                  },
                ),
                Expanded(
                  // <-- ใช้ Expanded
                  child: Align(
                    // <-- ใช้ Align
                    alignment: Alignment.center, // <-- จัดกลาง Row
                    child: const Text(
                      'รายละเอียดสินค้า',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20, // <-- ลดขนาดเล็กน้อย
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center, // <-- จัดกลางเผื่อข้อความยาว
                    ),
                  ),
                ),
                // SizedBox ทางขวาเพื่อให้ Title อยู่กลาง
                const SizedBox(
                  width: kToolbarHeight,
                ), // kToolbarHeight คือความกว้างมาตรฐานของ IconButton
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ฟังก์ชันสำหรับสร้างการ์ดรายละเอียดสินค้า --- (เหมือนเดิม)
  Widget _buildDetailCard({
    required String trackingId,
    required String sender,
    required String recipientName,
    required String recipientAddress,
    required String recipientPhone,
    required Color imagePlaceholderColor,
    required String driverName,
    required String shippingDate,
    required String deliveryDate,
  }) {
    const textStyleLabel = TextStyle(color: Colors.black54, fontSize: 14);
    const textStyleValue = TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ส่วน Tracking ID ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tracking ID', style: textStyleLabel),
                  Text(
                    trackingId,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text('ผู้ส่ง : $sender', style: textStyleValue),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          // --- ส่วนข้อมูลผู้รับ ---
          Text('ผู้รับ : $recipientName', style: textStyleValue),
          const SizedBox(height: 4),
          Text('ที่อยู่ผู้รับ : $recipientAddress', style: textStyleValue),
          const SizedBox(height: 4),
          Text('โทรศัพท์ : $recipientPhone', style: textStyleValue),
          const Divider(height: 24, thickness: 1),

          // --- ส่วนสิ่งของทั้งหมด ---
          const Text('สิ่งของทั้งหมด', style: textStyleValue),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: imagePlaceholderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              // child: Image.asset('path/to/your_image.png'), // หากมีรูปภาพจริง
            ),
          ),
          const SizedBox(height: 12),
          Text('คนขับ : $driverName', style: textStyleValue),
          const SizedBox(height: 4),
          Text('จัดส่งวันที่ : $shippingDate', style: textStyleValue),
          const SizedBox(height: 4),
          Text('ส่งถึงผู้รับ : $deliveryDate', style: textStyleValue),
        ],
      ),
    );
  }

  // --- ฟังก์ชัน BottomNav --- (เหมือนเดิม)
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146),
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      // currentIndex: ??? // <-- หน้ารายละเอียดปกติไม่มี index ใน BottomNav
      onTap: (index) {
        Widget page;
        switch (index) {
          case 0:
            page = const DeliveryPage();
            break;
          case 1:
            page = const HistoryPage();
            break;
          case 2:
            page = const MoreOptionsPage();
            break;
          default:
            page = const DeliveryPage(); // หน้าเริ่มต้น
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
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
} // <-- ปิดคลาส DetailPage

/// Class for clipping the AppBar (ต้องมีในไฟล์นี้)
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
