import 'package:delivery/user/detail.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/search.dart';
import 'package:delivery/user/status.dart'; // <-- Make sure StatusScreen is imported
import 'package:flutter/material.dart';

// ***** 1. เพิ่ม Imports สำหรับหน้าที่จะไป *****
import 'package:delivery/user/receive.dart'; // สำหรับปุ่ม 'ส่งสินค้า'
import 'package:delivery/user/tracking.dart'; // สำหรับปุ่ม 'สินค้าที่ต้องรับ'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery App',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        fontFamily: 'Kanit', // ตัวอย่างการใช้ฟอนต์ภาษาไทย (ถ้ามี)
      ),
      home: const ReceivePage(), // ตั้งค่าให้ ReceivePage เป็นหน้าแรก
      debugShowCheckedModeBanner: false, // ปิดแถบ Debug Banner
    );
  }
}

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ***** 2. เปลี่ยนโครงสร้าง Body ใหม่ *****
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // สีพื้นหลังเดิม
      body: SingleChildScrollView(
        // ใช้ SingleChildScrollView คลุมทั้งหมด
        child: Column(
          children: [
            // ***** 3. ใส่ Widget ส่วนหัวสีเหลือง (จาก DeliveryPage) *****
            _buildTopSection(),

            // ***** 4. ใส่ Widget ส่วนปุ่ม 3 ปุ่ม (จาก DeliveryPage) *****
            _buildButtonSection(context),

            // ***** 5. ใส่เนื้อหาเดิมของ ReceivePage *****
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                children: [
                  _buildContentTitle(), // "รายการสินค้าที่ต้องรับ" title
                  const SizedBox(height: 24),
                  // Delivery card 1
                  _buildDeliveryCard(
                    context,
                    senderLocation: 'หอพักอัครฉัตรแมนชั่น ตึกใหม่',
                    senderName: 'sathima kanlayasai',
                    recipientLocation: 'คณะวิทยาการสารสนเทศ',
                    recipientName: 'Soduku',
                  ),
                  const SizedBox(height: 16),
                  // Delivery card 2
                  _buildDeliveryCard(
                    context,
                    senderLocation: 'หอพักอัครฉัตรแมนชั่น ตึกใหม่',
                    senderName: 'sathima kanlayasai',
                    recipientLocation: 'คณะวิทยาการสารสนเทศ',
                    recipientName: 'Soduku',
                  ),
                  // --- ADDED GREEN BUTTON ---
                  _buildSubmitButton(context),
                  const SizedBox(
                    height: 24,
                  ), // Add some bottom padding if needed
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        context,
      ), // ใช้ BottomNav เดิม
    );
  }

  // ***** 6. Widget ใหม่: ส่วนบนของหน้า (จาก DeliveryPage) *****
  // (แก้ไขให้ใช้ค่าคงที่ เพราะหน้านี้เป็น StatelessWidget)
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
        // ใช้ SafeArea เฉพาะส่วนบน
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ใช้ Text คงที่ตามโค้ด ReceivePage เดิม
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
                color: const Color(0xFFA9A9A9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  // ใช้ Text คงที่ตามโค้ด ReceivePage เดิม
                  const Expanded(
                    child: Text(
                      'หอพักอัจฉราแมนชั่น ตึกใหม่',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  // ***** 7. Widget ใหม่: ส่วนของปุ่ม 3 ปุ่ม (จาก DeliveryPage) *****
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
                  context,
                  text: 'ส่งสินค้า',
                  icon: Icons.delivery_dining, // ไอคอนตามรูป
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  context,
                  text: 'สินค้าที่กำลังส่ง',
                  icon: Icons.local_shipping, // ไอคอนตามรูป
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: _buildReceivedButton(context),
          ), // ปุ่ม 'สินค้าที่ต้องรับ'
        ],
      ),
    );
  }

  // ***** 8. Widget ใหม่: ฟังก์ชันสร้างปุ่ม (จาก DeliveryPage) *****
  Widget _buildActionButton(
    BuildContext context, {
    required String text,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        if (text == 'ส่งสินค้า') {
          // หน้านี้คือ ReceivePage อยู่แล้ว อาจจะไม่ต้องทำอะไร หรือ refresh
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ReceivePage()),
          );
        } else if (text == 'สินค้าที่กำลังส่ง') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StatusScreen()),
          );
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
            Icon(icon, color: Colors.green, size: 40), // ไอคอนสีเขียวตามรูป
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ***** 9. Widget ใหม่: ฟังก์ชันสร้างปุ่ม 'สินค้าที่ต้องรับ' (จาก DeliveryPage) *****
  Widget _buildReceivedButton(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TrackingScreen()),
          );
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
              Icon(
                Icons.check_circle,
                color: Colors.blue[300],
                size: 40,
              ), // ไอคอนสีฟ้าตามรูป
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

  // --- (Widget เก่าที่ยังใช้งาน) ---

  // --- Content Title ("รายการสินค้าที่ต้องรับ") ---
  Widget _buildContentTitle() {
    return Container(
      width: double.infinity, // Make title container stretch full width
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.yellow.shade700,
          width: 1.5,
        ), // Yellow border
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
          'รายการสินค้าที่ต้องส่ง',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- Delivery Card ---
  Widget _buildDeliveryCard(
    BuildContext context, {
    required String senderLocation,
    required String senderName,
    required String recipientLocation,
    required String recipientName,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded corners
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
        crossAxisAlignment:
            CrossAxisAlignment.center, // Align items vertically center
        children: [
          // Delivery Icon Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Light grey background
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delivery_dining, // Delivery icon
              size: 40,
              color: Colors.green.shade700, // Green icon color
            ),
          ),
          const SizedBox(width: 16),
          // Location and Name Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(
                  icon: Icons.location_on,
                  color: Colors.red, // Red for sender
                  location: senderLocation,
                  person: 'ชื่อผู้ส่ง : $senderName',
                ),
                const SizedBox(height: 12),
                _buildLocationRow(
                  icon: Icons.location_on,
                  color: Colors.green, // Green for recipient
                  location: recipientLocation,
                  person: 'ชื่อผู้รับ : $recipientName',
                ),
                const SizedBox(height: 12),
                // Details Button aligned to the right
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DetailPage(), // Navigate to Detail Page
                        ),
                      );
                      print('กดปุ่ม รายละเอียด');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE428), // Yellow button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 0, // No shadow
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, // Fit content size
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
                          Icons.chevron_right, // Right arrow icon
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

  // --- NEW GREEN SUBMIT BUTTON WIDGET ---
  Widget _buildSubmitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          // Handle send product action
          print('กดปุ่ม ส่งสินค้า สีเขียว');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchRecipientScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 5,
        ),
        child: const Text(
          'ส่งสินค้า',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // --- Location Row Helper ---
  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String location,
    required String person,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align icon and text top
      children: [
        Icon(icon, color: color, size: 20), // Location icon
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Text
              Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              // Person Name Text
              Text(
                person,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ), // Greyish text
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146), // Yellow for selected item
      unselectedItemColor: const Color.fromARGB(
        255,
        20,
        19,
        19,
      ), // Dark grey for unselected
      currentIndex: 0, // Assuming this page is the first tab (index 0)
      onTap: (index) {
        // Handle navigation
        Widget page;
        bool shouldReplace = true; // Use pushReplacement by default

        switch (index) {
          case 0:
            // Already on this page, do nothing or maybe refresh
            return; // Exit if already on the current page
          case 1:
            page = const HistoryPage();
            shouldReplace = false; // Use push for History so user can go back
            break;
          case 2:
            page = const MoreOptionsPage();
            shouldReplace =
                false; // Use push for More Options so user can go back
            break;
          default:
            return; // Should not happen
        }

        if (shouldReplace) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
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
} // End of ReceivePage class

// ***** 10. ลบ CustomAppBarClipper ที่ไม่ใช้ออก *****
// class CustomAppBarClipper extends CustomClipper<Path> { ... }
