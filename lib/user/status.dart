import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ถ้าคุณมีหน้าเหล่านี้อยู่แล้วให้คง import ไว้
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';

class StatusScreen extends StatefulWidget {
  final String packageId; // ← ต้องส่งเข้ามาเสมอ
  const StatusScreen({super.key, required this.packageId});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  // สีหลัก
  static const Color primaryYellow = Color(0xFFFDE100);
  static const Color darkGreen = Color(0xFF98C21D);
  static const Color lightGrey = Color(0xFF9E9E9E);

  // Subscription เอกสาร package
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pkgSub;

  // STATE จาก Firestore
  String _status = 'pending'; // pending | accepted | on_delivery | delivered

  // ข้อมูลสินค้า
  String _productDescription = 'กำลังโหลดรายละเอียด...';
  String _productImageUrl = "https://via.placeholder.com/160?text=No+Image";

  // หลักฐานตอนส่งสำเร็จ (ไรเดอร์อัปโหลด)
  String? _proofPhoto1Url;
  String? _proofPhoto2Url;

  // ข้อมูลไรเดอร์
  String _riderName = 'รอไรเดอร์รับงาน';
  String _riderPhone = '—';
  String _riderPlate = '—';
  String _riderAvatar =
      'https://i.imgur.com/gX3tYlI.png'; // fallback avatar (ไม่ใช่ mock dataภาคเนื้อหา, เป็นรูปสำรองกรณีไม่มีใน DB)

  // สำหรับ BottomNav
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenPackage();
  }

  @override
  void dispose() {
    _pkgSub?.cancel();
    super.dispose();
  }

  // ฟังเอกสารแพ็กเกจแบบเรียลไทม์
  void _listenPackage() {
    _pkgSub?.cancel();
    _pkgSub = FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.packageId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      final data = snap.data()!;

      // สถานะ
      final status =
          (data['status'] as String?)?.trim().toLowerCase() ?? 'pending';

      // สินค้า: พยายามใช้ product_image_url ถ้ามี, ถ้าไม่มีค่อยลอง proof_image_url (เผื่อเก็บผิดฟิลด์ในอดีต)
      final productImg = (data['product_image_url'] as String?) ??
          (data['proof_image_url'] as String?) ??
          _productImageUrl;

      final productDesc =
          (data['package_description'] as String?) ?? 'ไม่ระบุรายละเอียด';

      // หลักฐานการส่ง (เมื่อ delivered)
      final p1 = data['proof_image_url_1'] as String?;
      final p2 = data['proof_image_url_2'] as String?;

      // ไรเดอร์
      String riderName = 'รอไรเดอร์รับงาน';
      String riderPhone = '—';
      String riderPlate = '—';
      String riderAvatar = _riderAvatar;

      // ถ้าเริ่มรับงานแล้ว (ไม่ใช่ pending) ให้แสดงข้อมูลไรเดอร์
      final riderId = data['rider_id'] as String?;
      if (riderId != null && status != 'pending') {
        final shortId = riderId.substring(0, min(6, riderId.length));
        // ถ้าในฐานะข้อมูลมีชื่อ/โทร/ป้ายทะเบียน/รูป ให้ใช้ของจริง
        riderName =
            (data['rider_name'] as String?) ?? 'Rider: $shortId...';
        riderPhone = (data['rider_phone'] as String?) ?? '—';
        riderPlate = (data['rider_plate'] as String?) ?? '—';
        riderAvatar =
            (data['rider_avatar'] as String?) ?? riderAvatar;
      }

      if (!mounted) return;
      setState(() {
        _status = status;

        _productDescription = productDesc;
        _productImageUrl = productImg;

        _proofPhoto1Url = p1;
        _proofPhoto2Url = p2;

        _riderName = riderName;
        _riderPhone = riderPhone;
        _riderPlate = riderPlate;
        _riderAvatar = riderAvatar;
      });
    }, onError: (e) {
      // คุณอาจโชว์ SnackBar แจ้งเตือนก็ได้
      debugPrint('status listen error: $e');
    });
  }

  // map status → step index 1..4
  int _activeStep() {
    switch (_status) {
      case 'accepted':
        return 2;
      case 'on_delivery':
        return 3;
      case 'delivered':
        return 4;
      case 'pending':
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = _activeStep();
    final isRiderAssigned = activeStep >= 2;
    final isDelivered = activeStep == 4;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        toolbarHeight: 90.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "สถานะการจัดส่งสินค้า",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStepper(activeStep),
            const SizedBox(height: 24),

            // สินค้า
            _buildSectionChip("สินค้าที่จะส่ง"),
            const SizedBox(height: 12),
            _buildProductCard(imageUrl: _productImageUrl, description: _productDescription),
            const SizedBox(height: 24),

            // ไรเดอร์
            _buildSectionChip("ข้อมูลไรเดอร์ที่รับงาน"),
            const SizedBox(height: 12),
            isRiderAssigned ? _buildRiderCard() : _buildWaitingRiderCard(),

            // หลักฐานเมื่อส่งสำเร็จ
            if (isDelivered && (_proofPhoto1Url != null || _proofPhoto2Url != null)) ...[
              const SizedBox(height: 24),
              _buildSectionChip("รูปถ่ายยืนยันการจัดส่ง"),
              const SizedBox(height: 12),
              _buildProofRow(_proofPhoto1Url, _proofPhoto2Url),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ---------- UI Widgets ----------

  Widget _buildSectionChip(String label) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: const Color(0xFFFFD900), width: 1.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFA6A000),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required String imageUrl,
    required String description,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปสินค้า
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // รายละเอียด
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รายละเอียดสินค้า:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    (description).isEmpty
                        ? 'ไม่ระบุรายละเอียด'
                        : description,
                    style: const TextStyle(color: Colors.black87),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRiderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(_riderAvatar),
          radius: 28,
          onBackgroundImageError: (_, __) {},
        ),
        title: Text(
          "ชื่อ : $_riderName",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("หมายเลขโทรศัพท์ : $_riderPhone", style: const TextStyle(fontSize: 13)),
            Text("หมายเลขทะเบียนรถ : $_riderPlate", style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingRiderCard() {
    return Card(
      color: Colors.grey[100],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              'รอไรเดอร์รับงาน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofRow(String? url1, String? url2) {
    return Row(
      children: [
        Expanded(child: _buildProofTile(url1, 'รูปที่ 1')),
        const SizedBox(width: 14),
        Expanded(child: _buildProofTile(url2, 'รูปที่ 2')),
      ],
    );
  }

  Widget _buildProofTile(String? url, String fallbackLabel) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? Center(
              child: Text(
              fallbackLabel,
              style: const TextStyle(color: Colors.grey),
            ))
          : null,
    );
  }

  // Stepper UI (แสดงสเต็ปสถานะ)
  Widget _buildStepper(int activeStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepItem(Icons.hourglass_top_rounded, "รอรับออเดอร์สินค้า", activeStep >= 1),
        _buildStepConnector(activeStep >= 2),
        _buildStepItem(Icons.assignment_turned_in_outlined, "ไรเดอร์รับงาน", activeStep >= 2),
        _buildStepConnector(activeStep >= 3),
        _buildStepItem(Icons.delivery_dining_outlined, "กำลังเดินทางส่งสินค้า", activeStep >= 3),
        _buildStepConnector(activeStep >= 4),
        _buildStepItem(Icons.check_circle_outline_rounded, "ส่งสินค้าเสร็จสิ้น", activeStep >= 4),
      ],
    );
  }

  Widget _buildStepItem(IconData icon, String label, bool isActive) {
    final Color iconBackgroundColor =
        isActive ? primaryYellow : Colors.grey.shade100;
    final Color iconColor = isActive ? darkGreen : lightGrey;
    final Color borderColor = isActive ? darkGreen : lightGrey;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBackgroundColor,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    final Color connectorColor = isActive ? darkGreen : lightGrey;
    return Expanded(
      child: Column(
        children: [
          Container(height: 3, color: connectorColor),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  // Bottom Navigation Bar (ถ้าไม่มี 3 หน้าเหล่านี้ ให้ลบ/ปรับตามโปรเจ็กต์ของคุณ)
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      backgroundColor: Colors.white,
      selectedItemColor: primaryYellow,
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      onTap: (index) {
        setState(() => _navIndex = index);
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryPage()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MoreOptionsPage()),
            );
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
