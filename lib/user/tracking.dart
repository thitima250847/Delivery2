import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:delivery/user/detail.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';

class TrackingScreen extends StatefulWidget {
  final String packageId; // ✅ ต้องส่งเข้ามา
  const TrackingScreen({super.key, required this.packageId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const Color primaryYellow = Color(0xFFFDE428);
  static const Color lightGreyBg = Color(0xFFF5F5F5);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  // ----- สถานะ/UI state -----
  String _riderName = 'กำลังโหลด...';
  String _riderPhone = 'กำลังโหลด...';
  String _riderPlate = 'กำลังโหลด...';
  int _currentStep = 0; // 0..3 = (pending, accepted, on_delivery, delivered)

  @override
  void initState() {
    super.initState();
    _listenPackage();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenPackage() {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.packageId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      final data = snap.data()!;
      final status = (data['status'] as String?)?.toLowerCase().trim() ?? 'pending';

      // map สถานะ → step index 0..3
      final step = switch (status) {
        'pending' => 0,
        'accepted' => 1,
        'on_delivery' => 2,
        'delivered' => 3,
        _ => 0,
      };

      // ถ้ามีฟิลด์ชื่ออื่น ให้เปลี่ยนตรงนี้ให้ตรง schema ของคุณ
      final riderName =
          (data['rider_name'] as String?) ??
          (data['rider_id'] != null ? 'Rider: ${data['rider_id']}' : 'ยังไม่มีไรเดอร์');
      final riderPhone = (data['rider_phone'] as String?) ?? 'ไม่ระบุ';
      final riderPlate = (data['rider_plate'] as String?) ?? 'ไม่ระบุ';

      if (!mounted) return;
      setState(() {
        _currentStep = step;
        _riderName = riderName;
        _riderPhone = riderPhone;
        _riderPlate = riderPlate;
      });
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBg,
      appBar: _buildCustomAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
          child: Column(
            children: [
              _buildMap(),
              const SizedBox(height: 24),
              // บล็อกสถานะตามเอกสาร Firestore ของ packageId ที่ส่งมา
              _buildRiderStatusBlock(
                context: context,
                riderName: _riderName,
                riderPhone: _riderPhone,
                riderPlate: _riderPlate,
                currentStep: _currentStep,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  /// Curved AppBar
  PreferredSize _buildCustomAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: ClipPath(
        clipper: CustomAppBarClipper(borderRadius: 30.0),
        child: Container(
          color: primaryYellow,
          padding: EdgeInsets.only(top: statusBarHeight),
          child: Center(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                const Text(
                  'สินค้าที่ต้องรับ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Map placeholder (สามารถแทนด้วยแผนที่จริงภายหลัง)
  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Image.network(
          "https://i.imgur.com/3Z0NpyA.png",
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Rider info + stepper block
  Widget _buildRiderStatusBlock({
    required BuildContext context,
    required String riderName,
    required String riderPhone,
    required String riderPlate,
    required int currentStep,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildRiderInfoCard(
            context: context,
            name: riderName,
            phone: riderPhone,
            licensePlate: riderPlate,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildStatusStepper(currentStep: currentStep),
        ),
      ],
    );
  }

  /// Rider info card
  Widget _buildRiderInfoCard({
    required BuildContext context,
    required String name,
    required String phone,
    required String licensePlate,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
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
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryYellow, width: 3),
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ชื่อ : $name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('หมายเลขโทรศัพท์ : $phone',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('หมายเลขทะเบียนรถ : $licensePlate',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {

              Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage()));
              // vvvv 2. [สำคัญ] ลองลบ const ถ้า DetailPage ไม่มี const constructor vvvv
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(packageId: '',),
                ), // <-- ลองลบ const
              );
              print('กดปุ่ม รายละเอียด');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('รายละเอียด',
                    style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: Colors.black, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Yellow stepper bar
  Widget _buildStatusStepper({required int currentStep}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: primaryYellow.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                height: 4.0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 25.0),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepItem(
                title: 'รอไรเดอร์รับสินค้า',
                iconData: Icons.hourglass_empty,
                stepIndex: 0,
                currentStep: currentStep,
              ),
              _buildStepItem(
                title: 'ไรเดอร์รับงาน',
                iconData: Icons.receipt_long,
                stepIndex: 1,
                currentStep: currentStep,
              ),
              _buildStepItem(
                title: 'กำลังเดินทางส่งสินค้า',
                iconData: Icons.delivery_dining,
                stepIndex: 2,
                currentStep: currentStep,
              ),
              _buildStepItem(
                title: 'ส่งสินค้าเสร็จสิ้น',
                iconData: Icons.check_circle_outline,
                stepIndex: 3,
                currentStep: currentStep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String title,
    required IconData iconData,
    required int stepIndex,
    required int currentStep,
  }) {
    Color iconColor = Colors.white;
    Color backgroundColor = Colors.grey.withOpacity(0.5);
    Color textColor = Colors.black54;

    if (stepIndex <= currentStep) {
      backgroundColor = Colors.white;
      iconColor = Colors.green;
      textColor = Colors.black;
    }
    if (stepIndex == currentStep) {
      iconColor = Colors.orange;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
            child: Icon(iconData, size: 28, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: primaryYellow,
      unselectedItemColor: Colors.black,
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      iconSize: 28,
      onTap: (index) {
        switch (index) {
          case 0:
            break; // หน้าปัจจุบัน
          case 1:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HistoryPage()));
            break;
          case 2:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MoreOptionsPage()));
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "หน้าแรก"),
        BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "ประวัติการส่งสินค้า"),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: "อื่นๆ"),
      ],
    );
  }
}

/// Clipper for AppBar
class CustomAppBarClipper extends CustomClipper<Path> {
  final double borderRadius;
  CustomAppBarClipper({this.borderRadius = 20.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - borderRadius);
    path.quadraticBezierTo(0, size.height, borderRadius, size.height);
    path.lineTo(size.width - borderRadius, size.height);
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - borderRadius);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
