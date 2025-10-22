// status_detail.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// แผนที่
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

// หน้าหลักอื่นๆ
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';

class StatusDetailScreen extends StatefulWidget {
  final String packageId;
  const StatusDetailScreen({super.key, required this.packageId});

  @override
  State<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends State<StatusDetailScreen> {
  // สีหลัก
  static const Color primaryYellow = Color(0xFFFDE100);
  static const Color darkGreen = Color(0xFF98C21D);
  static const Color lightGrey = Color(0xFF9E9E9E);

  // ... (State variables และฟังก์ชัน helpers ทั้งหมดเหมือนเดิม) ...
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pkgSub;
  final MapController _mapController = MapController();
  final Map<String, Map<String, dynamic>> _riderCache = {};

  latlong.LatLng _riderLocation = const latlong.LatLng(0, 0);
  latlong.LatLng _pickupLocation = const latlong.LatLng(13.7563, 100.5018);
  latlong.LatLng _destinationLocation = const latlong.LatLng(13.7563, 100.5018);

  String _status = 'pending';
  String _productDescription = 'กำลังโหลดรายละเอียด...';
  String _productImageUrl = "https-via.placeholder.com/160?text=No+Image";
  String? _proofPhoto1Url;
  String? _proofPhoto2Url;

  String _riderName = 'รอไรเดอร์รับงาน';
  String _riderPhone = '—';
  String _riderPlate = '—';
  String _riderAvatar = 'https-i.imgur.com/gX3tYlI.png';

  String _senderName = 'กำลังโหลด...';
  String _senderPhone = '—';

  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenPackage(widget.packageId);
  }

  @override
  void dispose() {
    _pkgSub?.cancel();
    super.dispose();
  }

  String _str(dynamic v) => (v == null) ? '' : v.toString();

  String _pickFirst(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final parts = k.split('.');
      dynamic cur = m;
      for (final p in parts) {
        if (cur is Map && cur.containsKey(p)) {
          cur = cur[p];
        } else {
          cur = null;
          break;
        }
      }
      if (cur != null && cur.toString().trim().isNotEmpty) {
        return cur.toString();
      }
    }
    return '';
  }

  Map<String, dynamic> _normalizeRider(Map<String, dynamic> riderDoc,
      {Map<String, dynamic>? fromPackage}) {
    final fallback = fromPackage ?? {};
    String name = _pickFirst(riderDoc, [
      'name',
      'displayName',
      'rider_name',
      'fullName',
      'fullname',
    ]);
    if (name.isEmpty) {
      final fname = _pickFirst(riderDoc, ['firstname', 'firstName']);
      final lname = _pickFirst(riderDoc, ['lastname', 'lastName', 'surname']);
      name = [fname, lname].where((e) => e.isNotEmpty).join(' ');
    }
    if (name.isEmpty) {
      name = _pickFirst(fallback, ['rider_name', 'riderInfo.name', 'name']);
    }
    String avatar = _pickFirst(riderDoc, [
      'avatar_url',
      'profile',
      'profileUrl',
      'profileURL',
      'image',
      'imageUrl',
      'photoURL',
      'photoUrl',
      'profileImage',
    ]);
    if (avatar.isEmpty) {
      avatar = _pickFirst(fallback, [
        'rider_avatar',
        'riderInfo.avatar',
        'rider_info.avatar',
        'rider.profile',
      ]);
    }
    String phone = _pickFirst(riderDoc, [
      'phone_number',
      'phone',
      'mobile',
      'tel',
      'telephone',
      'contact',
    ]);
    if (phone.isEmpty) {
      phone = _pickFirst(fallback, [
        'rider_phone',
        'riderInfo.phone',
        'rider_info.phone',
        'rider.phone',
      ]);
    }
    String plate = _pickFirst(riderDoc, [
      'license_plate',
      'licensePlate',
      'plate',
      'plateNumber',
      'car_plate',
      'vehicle_plate',
      'vehicle_registration_number',
    ]);
    if (plate.isEmpty) {
      plate = _pickFirst(fallback, [
        'rider_plate',
        'riderInfo.plate',
        'rider_info.plate',
        'rider.plate',
        'vehicle.plate',
      ]);
    }
    return {
      'name': _str(name),
      'avatar_url': _str(avatar),
      'phone_number': _str(phone),
      'license_plate': _str(plate),
    };
  }

  void _listenPackage(String packageId) {
    _pkgSub?.cancel();
    _pkgSub = FirebaseFirestore.instance
        .collection('packages')
        .doc(packageId)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists || snap.data() == null) return;
      final data = snap.data()!;
      final status =
          (data['status'] as String?)?.trim().toLowerCase() ?? 'pending';
      final riderId = data['rider_id'] as String?;
      Map<String, dynamic>? riderData;
      if (riderId != null &&
          status != 'pending' &&
          _riderCache[riderId] == null) {
        try {
          final riderDoc = await FirebaseFirestore.instance
              .collection('riders')
              .doc(riderId)
              .get();
          if (riderDoc.exists) {
            _riderCache[riderId] =
                _normalizeRider(riderDoc.data() ?? {}, fromPackage: data);
          }
        } catch (e) {
          debugPrint('Error fetching rider data: $e');
        }
      }
      riderData = (riderId != null)
          ? _riderCache[riderId] ?? _normalizeRider({}, fromPackage: data)
          : _normalizeRider({}, fromPackage: data);
      final productImg =
          (data['proof_image_url'] as String?) ?? _productImageUrl;
      final productDesc =
          (data['package_description'] as String?) ?? 'ไม่ระบุรายละเอียด';
      final p1 = data['proof_image_url_1'] as String?;
      final p2 = data['proof_image_url_2'] as String?;
      String riderName = riderData['name']?.toString().trim().isNotEmpty == true
          ? riderData['name']
          : (riderId != null
              ? 'Rider: ${riderId.substring(0, min(6, riderId.length))}...'
              : 'รอไรเดอร์รับงาน');
      final riderPhone = riderData['phone_number'] ?? '—';
      final riderPlate = riderData['license_plate'] ?? '—';
      final riderAvatar =
          (riderData['avatar_url']?.toString().trim().isNotEmpty == true)
              ? riderData['avatar_url']
              : _riderAvatar;
      final riderLat = (data['rider_lat'] as num?)?.toDouble() ?? 0.0;
      final riderLng = (data['rider_lng'] as num?)?.toDouble() ?? 0.0;
      final receiverInfo =
          (data['receiver_info'] as Map<String, dynamic>?) ?? {};
      final destinationLat = (receiverInfo['lat'] as num?)?.toDouble() ?? 0.0;
      final destinationLng = (receiverInfo['lng'] as num?)?.toDouble() ?? 0.0;

      final senderInfo = (data['sender_info'] as Map<String, dynamic>?) ?? {};
      final pickupLat = (senderInfo['lat'] as num?)?.toDouble() ?? 0.0;
      final pickupLng = (senderInfo['lng'] as num?)?.toDouble() ?? 0.0;
      final senderName = senderInfo['name'] as String? ?? 'ไม่ระบุ';
      final senderPhone = senderInfo['phone'] as String? ?? '—';

      if (!mounted) return;
      setState(() {
        _status = status;
        _productDescription = productDesc;
        _productImageUrl = productImg;
        _proofPhoto1Url = p1;
        _proofPhoto2Url = p2;
        _riderName = riderName;
        _riderPhone = riderPhone.toString();
        _riderPlate = riderPlate.toString();
        _riderAvatar = riderAvatar.toString();
        _riderLocation = latlong.LatLng(riderLat, riderLng);
        _destinationLocation = latlong.LatLng(destinationLat, destinationLng);
        _pickupLocation = latlong.LatLng(pickupLat, pickupLng);
        _senderName = senderName;
        _senderPhone = senderPhone;

        if (riderLat != 0.0) {
          _mapController.move(_riderLocation, 14.0);
        } else if (destinationLat != 0.0) {
          _mapController.move(_destinationLocation, 14.0);
        }
      });
    }, onError: (e) => debugPrint('status listen error: $e'));
  }

  int _activeStep(String? s) {
    final status = (s ?? _status).toLowerCase().trim();
    switch (status) {
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
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _buildDetailBody(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildDetailBody() {
    final activeStep = _activeStep(null);
    final isRiderAssigned = activeStep >= 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStepper(activeStep),
          const SizedBox(height: 24),
          _buildSectionChip("ตำแหน่งการจัดส่ง"),
          const SizedBox(height: 12),
          _buildMapCard(isRiderAssigned),
          const SizedBox(height: 24),
          _buildSectionChip("สินค้าที่จะส่ง"),
          const SizedBox(height: 12),
          _buildProductCard(
              imageUrl: _productImageUrl, description: _productDescription),
          const SizedBox(height: 24),
          _buildSectionChip("ข้อมูลผู้ส่ง"),
          const SizedBox(height: 12),
          _buildSenderDetailCard(),
          const SizedBox(height: 24),
          _buildSectionChip("ข้อมูลไรเดอร์ที่รับงาน"),
          const SizedBox(height: 12),
          isRiderAssigned ? _buildRiderDetailCard() : _buildWaitingRiderCard(),
          if (_proofPhoto1Url != null || _proofPhoto2Url != null) ...[
            const SizedBox(height: 24),
            _buildSectionChip("รูปถ่ายยืนยันการจัดส่ง"),
            const SizedBox(height: 12),
            _buildProofRow(_proofPhoto1Url, _proofPhoto2Url),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- (Widget builders อื่นๆ ส่วนใหญ่เหมือนเดิม) ---

  Widget _buildMapCard(bool isRiderAssigned) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    final bool isLocationAvailable =
        _destinationLocation.latitude != 0.0 || _riderLocation.latitude != 0.0;
    if (!isLocationAvailable) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('ไม่พบข้อมูลตำแหน่งบนแผนที่',
              style: TextStyle(color: lightGrey)),
        ),
      );
    }
    final initialCenter =
        _riderLocation.latitude != 0.0 ? _riderLocation : _destinationLocation;
    final List<Marker> markers = [];
    if (_pickupLocation.latitude != 0.0) {
      markers.add(Marker(
        point: _pickupLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.store, color: Color.fromARGB(255, 162, 0, 255), size: 40),
      ));
    }
    if (_destinationLocation.latitude != 0.0) {
      markers.add(Marker(
        point: _destinationLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }
    if (isRiderAssigned && _riderLocation.latitude != 0.0) {
      markers.add(Marker(
        point: _riderLocation,
        width: 40,
        height: 40,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration:
              const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: const Icon(Icons.motorcycle, color: Colors.white, size: 22),
        ),
      ));
    }
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.flutter.my_delivery_app',
              ),
              MarkerLayer(markers: markers),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    isRiderAssigned &&
                            _riderLocation.latitude != 0.0 &&
                            _activeStep(null) < 4
                        ? 'ไรเดอร์อยู่ใกล้ Lat:${_riderLocation.latitude.toStringAsFixed(4)}, Lon:${_riderLocation.longitude.toStringAsFixed(4)}'
                        : (_activeStep(null) == 4
                            ? 'สินค้าจัดส่งสำเร็จแล้ว'
                            : (isRiderAssigned
                                ? 'ไรเดอร์รับงานแล้ว: รอสัญญาณ GPS'
                                : 'รอไรเดอร์รับงาน...')),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSenderDetailCard() {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueGrey, width: 3),
            color: Colors.grey[200],
          ),
          child: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, color: Colors.black54, size: 30)),
        ),
        title: Text("ชื่อผู้ส่ง : $_senderName",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("หมายเลขโทรศัพท์ : $_senderPhone",
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildRiderDetailCard() {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    final bool isAvatarUrlValid = _riderAvatar.isNotEmpty &&
        _riderAvatar != 'https-i.imgur.com/gX3tYlI.png';
    final ImageProvider? backgroundImage =
        isAvatarUrlValid ? NetworkImage(_riderAvatar) : null;
    final ImageErrorListener? backgroundErrorListener = isAvatarUrlValid
        ? (exception, stackTrace) =>
            debugPrint('Error loading rider avatar: $exception')
        : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryYellow, width: 3),
            color: Colors.grey[200],
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundImage: backgroundImage,
            onBackgroundImageError: backgroundErrorListener,
            child: isAvatarUrlValid
                ? null
                : const Icon(Icons.motorcycle, color: Colors.black54, size: 30),
          ),
        ),
        title: Text("ชื่อ : $_riderName",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("หมายเลขโทรศัพท์ : $_riderPhone",
                style: const TextStyle(fontSize: 13)),
            Text("หมายเลขทะเบียนรถ : $_riderPlate",
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionChip(String label) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
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
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รายละเอียดสินค้า:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    (description).isEmpty ? 'ไม่ระบุรายละเอียด' : description,
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

  Widget _buildWaitingRiderCard() {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
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
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    return Row(
      children: [
        Expanded(child: _buildProofTile(url1, 'รูปที่ 1')),
        const SizedBox(width: 14),
        Expanded(child: _buildProofTile(url2, 'รูปที่ 2')),
      ],
    );
  }

  Widget _buildProofTile(String? url, String fallbackLabel) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
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

  Widget _buildStepper(int activeStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepItem(
            Icons.hourglass_top_rounded, "รอรับออเดอร์สินค้า", activeStep >= 1),
        _buildStepConnector(activeStep >= 2),
        _buildStepItem(Icons.assignment_turned_in_outlined, "ไรเดอร์รับงาน",
            activeStep >= 2),
        _buildStepConnector(activeStep >= 3),
        _buildStepItem(Icons.delivery_dining_outlined, "กำลังเดินทางส่งสินค้า",
            activeStep >= 3),
        _buildStepConnector(activeStep >= 4),
        _buildStepItem(Icons.check_circle_outline_rounded, "ส่งสินค้าเสร็จสิ้น",
            activeStep >= 4),
      ],
    );
  }

  // VVVVVV จุดที่แก้ไข VVVVVV
  Widget _buildStepItem(IconData icon, String label, bool isActive) {
    final Color iconColor = isActive ? darkGreen : Colors.white;
    final Color backgroundColor =
        isActive ? Colors.white : Colors.grey.withOpacity(0.5);
    final Color textColor = isActive ? Colors.black : Colors.black54;
    final Color borderColor = isActive ? darkGreen : lightGrey;
    return Expanded(
      child: Column(
        // เพิ่ม: จัดให้อยู่บนสุดและมีความสูงคงที่
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          // เพิ่ม: SizedBox เพื่อบังคับความสูงของ Text
          SizedBox(
            height: 30, // กำหนดความสูงให้พอดีสำหรับ 2 บรรทัด
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^

  Widget _buildStepConnector(bool isActive) {
    final Color connectorColor = isActive ? darkGreen : lightGrey;
    return Expanded(
      child: Column(
        children: [
          // จัดตำแหน่งของเส้นเชื่อมให้อยู่ตรงกลางของ Icon
          const SizedBox(height: 22),
          Container(height: 3, color: connectorColor),
          const SizedBox(height: 52),
        ],
      ),
    );
  }

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
        BottomNavigationBarItem(
            icon: Icon(Icons.history), label: 'ประวัติการส่งสินค้า'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'อื่นๆ'),
      ],
    );
  }
}
