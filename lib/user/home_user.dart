// home_user.dart

import 'package:delivery/user/receive.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// หน้านำทาง
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/tracking.dart';
import 'package:delivery/user/status.dart'; // änner เพิ่ม: import StatusScreen

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  String? _userName;
  String? _userAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final name = data['name'] as String?;
        final addresses = data['addresses'] as List<dynamic>?;
        String? addressText;
        if (addresses != null && addresses.isNotEmpty) {
          final firstAddress = addresses[0] as Map<String, dynamic>;
          addressText = firstAddress['address_text'] as String?;
        }

        setState(() {
          _userName = name;
          _userAddress = addressText;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // änner แก้ไข: ใช้ userField แทน customerField
  Future<String?> _findActivePackageId({
    required String userField,
    required List<String> statuses,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final q = await FirebaseFirestore.instance
          .collection('packages')
          .where(userField, isEqualTo: user.uid)
          .where('status', whereIn: statuses)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return null;
      return q.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  // änner แก้ไข: นำทางไปหน้า Tracking Screen หรือ Status Screen โดยจัดการค่า null
  Future<void> _navigateToTrackingPage(BuildContext context, {required bool isReceiving}) async {
    String? pkgId;
    
    if (isReceiving) {
      // 1. สำหรับ 'สินค้าที่ต้องรับ' (ผู้ใช้คือ Receiver)
      pkgId = await _findActivePackageId(
        userField: 'receiver_user_id', // ค้นหาในฐานะผู้รับ
        statuses: const ['accepted', 'on_delivery'],
      );
    } else {
      // 2. สำหรับ 'สินค้าที่กำลังส่ง' (ผู้ใช้คือ Sender)
      pkgId = await _findActivePackageId(
        userField: 'sender_user_id', // ค้นหาในฐานะผู้ส่ง
        statuses: const ['pending', 'accepted', 'on_delivery'],
      );
    }

    if (!mounted) return;
    
    // 3. ตรวจสอบค่า pkgId ก่อนนำทาง (แก้ String? can't be assigned to String)
    if (pkgId == null) {
      // แสดงข้อความแจ้งเตือนที่เหมาะสม
      final String message = isReceiving 
          ? 'ยังไม่มีสินค้ากำลังจัดส่งมาถึงคุณ'
          : 'ยังไม่มีออเดอร์ที่กำลังดำเนินการ';
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );

      // หากไม่มี Package ที่กำลังใช้งานอยู่ ให้ส่ง packageId เป็น null ไปยัง TrackingScreen
      if (!isReceiving) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(packageId: null)),
        );
      }
      return;
    }

    // 4. นำทางไปยังหน้าจอที่ถูกต้อง (ใช้ pkgId! เพื่อยืนยันว่าไม่ใช่ null)
    if (isReceiving) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StatusScreen(packageId: pkgId!)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrackingScreen(packageId: pkgId!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    imageUrl: 'https://img.youtube.com/vi/Tb_H0-BavZY/sddefault.jpg',
                    title: 'กว่าจะเป็น ‘สันติ’',
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

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
                Text(
                  'สวัสดี ${_userName ?? 'ผู้ใช้งาน'}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 28, color: Colors.white),
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
                  Expanded(
                    child: Text(
                      _userAddress ?? 'ไม่พบที่อยู่',
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
          Center(child: _buildReceivedButton(context)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String text,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () async {
        if (text == 'ส่งสินค้า') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivePage()));
        } else if (text == 'สินค้าที่กำลังส่ง') {
          await _navigateToTrackingPage(context, isReceiving: false);
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedButton(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () async {
          await _navigateToTrackingPage(context, isReceiving: true);
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
            Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: 200),
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
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(description, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
            break;
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
            break;
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MoreOptionsPage()));
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'ประวัติการส่งสินค้า'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'อื่นๆ'),
      ],
    );
  }
}