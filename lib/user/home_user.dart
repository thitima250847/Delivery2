import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// หน้านำทาง (ที่ไม่เปลี่ยน)
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/search.dart';
import 'package:delivery/user/status.dart';
import 'package:delivery/user/tracking.dart';

// ***** 1. แปลงเป็น StatefulWidget *****
class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  // ***** 2. สร้างตัวแปรเพื่อเก็บข้อมูลผู้ใช้และสถานะการโหลด *****
  String? _userName;
  String? _userAddress;
  bool _isLoading = true;

  // ***** 3. สร้างฟังก์ชันดึงข้อมูลเมื่อหน้าจอถูกสร้าง *****
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // ดึงข้อมูลผู้ใช้ที่ล็อกอินปัจจุบัน
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String uid = currentUser.uid;

        // ดึงเอกสารของผู้ใช้จาก Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          // แปลงข้อมูลเป็น Map
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          // ดึงชื่อ
          final name = data['name'] as String?;

          // ดึงที่อยู่ (จากใน array 'addresses')
          final addresses = data['addresses'] as List<dynamic>?;
          String? addressText;
          if (addresses != null && addresses.isNotEmpty) {
            final firstAddress = addresses[0] as Map<String, dynamic>;
            addressText = firstAddress['address_text'] as String?;
          }

          // อัปเดต State เพื่อให้ UI แสดงผลใหม่
          setState(() {
            _userName = name;
            _userAddress = addressText;
            _isLoading = false; // โหลดเสร็จแล้ว
          });
        }
      } else {
         setState(() {
            _isLoading = false;
         });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false; // หากเกิดข้อผิดพลาดให้หยุดโหลด
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ***** 4. แสดงผลตามสถานะการโหลด *****
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // ขณะโหลด
          : SingleChildScrollView( // เมื่อโหลดเสร็จแล้ว
              child: Column(
                children: [
                  _buildTopSection(),
                  _buildButtonSection(context),
                  const SizedBox(height: 20),
                  _buildAdCard(
                    imageUrl:
                        'https://moviedelic.com/wp-content/uploads/2025/05/Mad-Unicornuniversal-base_na_01_zxx-1-e1748597704822.jpg',
                    title: 'TUNDER EXPRESS',
                  ),
                  const SizedBox(height: 20),
                  _buildAdCard(
                    imageUrl:
                        'https://img.youtube.com/vi/Tb_H0-BavZY/sddefault.jpg',
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
                // ***** 5. เปลี่ยนมาใช้ข้อมูลจาก State *****
                Text(
                  'สวัสดี ${_userName ?? 'ผู้ใช้งาน'}', // ใช้ชื่อที่ดึงมา
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  // ***** 6. เปลี่ยนมาใช้ข้อมูลที่อยู่จาก State *****
                  Expanded(
                    child: Text(
                      _userAddress ?? 'ไม่พบที่อยู่', // ใช้ที่อยู่ที่ดึงมา
                      style: const TextStyle(
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

  // ส่วนของปุ่ม 3 ปุ่ม (โค้ดเดิม)
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
                  icon: Icons.delivery_dining,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  context,
                  text: 'สินค้าที่กำลังส่ง',
                  icon: Icons.local_shipping,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: _buildReceivedButton(context),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มสำหรับ 'ส่งสินค้า' และ 'สินค้าที่กำลังส่ง' (โค้ดเดิม)
  Widget _buildActionButton(
    BuildContext context, {
    required String text,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        if (text == 'ส่งสินค้า') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchRecipientScreen(),
            ),
          );
        } else if (text == 'สินค้าที่กำลังส่ง') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StatusScreen(),
            ),
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
            Icon(icon, color: Colors.green, size: 40),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มสำหรับ 'สินค้าที่ต้องรับ' (โค้ดเดิม)
  Widget _buildReceivedButton(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrackingScreen(),
            ),
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

  // ส่วนของการ์ดรูปภาพ (โค้ดเดิม)
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

  // ส่วนเมนูด้านล่าง (โค้ดเดิม)
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146),
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      onTap: (index) {
        switch (index) {
          case 0:
            // ไม่ต้องทำอะไรเพราะอยู่หน้าแรกแล้ว
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