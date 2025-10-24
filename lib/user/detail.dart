import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart' hide CustomAppBarClipper;
import 'package:flutter/material.dart';
import 'package.cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final String packageId;

  const DetailPage({
    super.key,
    required this.packageId,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  static const Color primaryYellow = Color(0xFFFDE428);

  Map<String, dynamic>? _packageData;
  Map<String, dynamic>? _riderData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPackageDetails();
  }

  Future<void> _fetchPackageDetails() async {
    try {
      final packageDoc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .get();

      if (!packageDoc.exists) {
        throw Exception("ไม่พบข้อมูลพัสดุ");
      }

      final packageData = packageDoc.data()!;
      _packageData = packageData;

      final riderId = packageData['rider_id'];
      if (riderId != null && riderId is String && riderId.isNotEmpty) {
        final riderDoc = await FirebaseFirestore.instance
            .collection('riders')
            .doc(riderId)
            .get();
        if (riderDoc.exists) {
          _riderData = riderDoc.data();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = timestamp.toDate();
    final formatter =
        DateFormat('dd/MM/${dateTime.year + 543} เวลา HH:mm', 'th_TH');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildCustomAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _packageData == null
              ? const Center(child: Text("ไม่พบข้อมูล"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDetailCard(),
                ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildDetailCard() {
    final receiverInfo =
        _packageData?['receiver_info'] as Map<String, dynamic>? ?? {};
    final senderInfo =
        _packageData?['sender_info'] as Map<String, dynamic>? ?? {};
    final imageUrl = _packageData?['proof_image_url'] as String? ?? '';
    // ดึงข้อมูลรายละเอียดสินค้า
    final packageDescription =
        _packageData?['package_description'] as String? ?? 'ไม่มีรายละเอียด';

    final shippingDate =
        _formatTimestamp(_packageData?['created_at'] as Timestamp?);
    final deliveryDate =
        _formatTimestamp(_packageData?['delivered_at'] as Timestamp?);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tracking ID', style: textStyleLabel),
                  Text(
                    '#${widget.packageId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text('ผู้ส่ง : ${senderInfo['name'] ?? 'XXX'}',
                  style: textStyleValue),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Text('ผู้รับ : ${receiverInfo['name'] ?? 'ไม่ระบุ'}',
              style: textStyleValue),
          const SizedBox(height: 4),
          Text('ที่อยู่ผู้รับ : ${receiverInfo['address'] ?? 'ไม่ระบุ'}',
              style: textStyleValue),
          const SizedBox(height: 4),
          Text('โทรศัพท์ : ${receiverInfo['phone'] ?? 'ไม่ระบุ'}',
              style: textStyleValue),
          const Divider(height: 24, thickness: 1),
          // แสดงรายละเอียดสินค้าที่เพิ่มเข้ามา
          const Text('ชื่อสินค้า:',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(packageDescription, style: textStyleValue),
          const SizedBox(height: 12),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade200,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, color: Colors.red),
                      )
                    : const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_riderData != null) ...[
            Text('คนขับ : ${_riderData?['name'] ?? 'N/A'}',
                style: textStyleValue),
            const SizedBox(height: 4),
            Text('ป้ายทะเบียน : ${_riderData?['license_plate'] ?? 'N/A'}',
                style: textStyleValue),
          ] else ...[
            const Center(
              child: Text(
                'รอไรเดอร์รับงาน...',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('จัดส่งวันที่ : $shippingDate', style: textStyleValue),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  PreferredSize _buildCustomAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return PreferredSize(
      preferredSize: const Size.fromHeight(100.0),
      child: ClipPath(
        clipper: CustomAppBarClipper(borderRadius: 20.0),
        child: Container(
          color: primaryYellow,
          padding: EdgeInsets.only(
            top: statusBarHeight,
          ),
          child: Center(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: const Text(
                      'รายละเอียดสินค้า',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(
                  width: kToolbarHeight,
                ),
              ],
            ),
          ),
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
            page = const DeliveryPage();
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