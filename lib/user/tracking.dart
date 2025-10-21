// tracking.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

import 'package:delivery/user/detail.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';

// Helper class: เพิ่มข้อมูลไรเดอร์ (ไม่มีการเปลี่ยนแปลง)
class PackageInfo {
  final String id;
  final int currentStep;
  final String status;
  final Timestamp? deliveredAt;
  final latlong.LatLng riderLocation;
  final latlong.LatLng destinationLocation;
  // änner เพิ่ม: pickupLocation เพื่อใช้เป็นหมุดสีเขียว
  final latlong.LatLng pickupLocation;
  final String riderName;
  final String riderPhone;
  final String riderPlate;

  PackageInfo({
    required this.id,
    this.currentStep = 0,
    required this.status,
    this.deliveredAt,
    required this.riderLocation,
    required this.destinationLocation,
    required this.pickupLocation, // änner เพิ่ม
    this.riderName = 'กำลังค้นหา...',
    this.riderPhone = '...',
    this.riderPlate = '...',
  });
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, String? packageId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const Color primaryYellow = Color(0xFFFDE428);
  static const Color lightGreyBg = Color(0xFFF5F5F5);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final MapController _mapController = MapController();

  List<PackageInfo> _allActivePackages = [];
  bool _isLoading = true;
  final Map<String, Map<String, dynamic>> _riderCache = {};

  @override
  void initState() {
    super.initState();
    _listenToActivePackages();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenToActivePackages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final query = FirebaseFirestore.instance
        .collection('packages')
        .where('sender_user_id', isEqualTo: user.uid)
        .where('status',
            whereIn: ['pending', 'accepted', 'on_delivery', 'delivered']);

    _sub = query.snapshots().listen((snapshot) async {
      List<Map<String, dynamic>> rawPackages = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      for (var pkg in rawPackages) {
        final riderId = pkg['rider_id'] as String?;
        if (riderId != null && _riderCache[riderId] == null) {
          try {
            final riderDoc = await FirebaseFirestore.instance
                .collection('riders')
                .doc(riderId)
                .get();
            if (riderDoc.exists) {
              _riderCache[riderId] = riderDoc.data()!;
            }
          } catch (e) {
            // Handle error
          }
        }
      }

      final packages = rawPackages.map((pkg) {
        final riderData = _riderCache[pkg['rider_id'] as String?];
        final status =
            (pkg['status'] as String?)?.toLowerCase().trim() ?? 'pending';
        final step = switch (status) {
          'pending' => 0,
          'accepted' => 1,
          'on_delivery' => 2,
          'delivered' => 3,
          _ => 0,
        };

        final riderLat = (pkg['rider_lat'] as num?)?.toDouble() ?? 0.0;
        final riderLng = (pkg['rider_lng'] as num?)?.toDouble() ?? 0.0;

        final receiverInfo =
            (pkg['receiver_info'] as Map<String, dynamic>?) ?? {};
        final destLat = (receiverInfo['lat'] as num?)?.toDouble() ?? 0.0;
        final destLng = (receiverInfo['lng'] as num?)?.toDouble() ?? 0.0;

        // änner ดึงพิกัดจุดรับสินค้าจาก sender_info
        final senderInfo = (pkg['sender_info'] as Map<String, dynamic>?) ?? {};
        final pickupLat = (senderInfo['lat'] as num?)?.toDouble() ?? 0.0;
        final pickupLng = (senderInfo['lng'] as num?)?.toDouble() ?? 0.0;

        return PackageInfo(
          id: pkg['id'],
          status: status,
          currentStep: step,
          deliveredAt: pkg['delivered_at'] as Timestamp?,
          riderLocation: latlong.LatLng(riderLat, riderLng),
          destinationLocation: latlong.LatLng(destLat, destLng),
          pickupLocation: latlong.LatLng(pickupLat, pickupLng), // änner เพิ่ม
          riderName: riderData?['name'] ?? 'ยังไม่มีผู้รับงาน',
          riderPhone: riderData?['phone_number'] ?? '-',
          riderPlate: riderData?['license_plate'] ?? '-',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allActivePackages = packages;
          _isLoading = false;
        });
        if (_allActivePackages.any((p) => p.status == 'delivered')) {
          Timer(const Duration(seconds: 11), () {
            if (mounted) setState(() {});
          });
        }
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();
    final packagesToShow = _allActivePackages.where((p) {
      if (p.status != 'delivered') return true;
      if (p.deliveredAt == null) return false;
      return (now.seconds - p.deliveredAt!.seconds) <= 10;
    }).toList();

    return Scaffold(
      backgroundColor: lightGreyBg,
      appBar: _buildCustomAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryYellow))
          : packagesToShow.isEmpty
              ? const Center(
                  child: Text(
                    'ยังไม่มีออเดอร์ที่กำลังส่ง',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                    child: Column(
                      children: [
                        _buildMultiRiderMap(packagesToShow),
                        const SizedBox(height: 24),
                        ...packagesToShow.map((package) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildRiderStatusBlock(
                                context: context, package: package),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildMultiRiderMap(List<PackageInfo> packages) {
    // Map สำหรับรวมป้ายทะเบียนของหมุดที่อยู่พิกัดเดียวกัน
    final Map<latlong.LatLng, List<String>> riderLocations = {};
    final Map<latlong.LatLng, List<String>> pickupLocations = {}; // änner เพิ่ม
    final Map<latlong.LatLng, List<String>> destinationLocations = {};

    for (var package in packages) {
      if (package.status == 'accepted' ||
          package.status == 'on_delivery' ||
          package.status == 'delivered') {
        // 1. รวบรวมตำแหน่งไรเดอร์ (รถ)
        if (package.riderLocation.latitude != 0.0) {
          final loc = package.riderLocation;
          riderLocations.putIfAbsent(loc, () => []).add(package.riderPlate);
        }

        // 2. รวบรวมตำแหน่งจุดรับสินค้า (หมุดสีเขียว)
        if (package.pickupLocation.latitude != 0.0) {
          final loc = package.pickupLocation;
          pickupLocations.putIfAbsent(loc, () => []).add(package.riderPlate);
        }

        // 3. รวบรวมตำแหน่งจุดส่งสินค้า (หมุดสีแดง)
        if (package.destinationLocation.latitude != 0.0) {
          final loc = package.destinationLocation;
          destinationLocations
              .putIfAbsent(loc, () => [])
              .add(package.riderPlate);
        }
      }
    }

    final List<Marker> markers = [];

    // 4. สร้าง Marker สำหรับตำแหน่งไรเดอร์ (รถ สีน้ำเงิน)
    riderLocations.forEach((location, plates) {
      final label = plates.join(', ');
      markers.add(Marker(
          point: location,
          width: 100,
          height: 80,
          child: _buildMarkerWithLabel(
            position: location,
            label: label,
            icon: Icons.delivery_dining,
            iconColor: Colors.blueAccent,
          )));
    });

    // 5. สร้าง Marker สำหรับตำแหน่งจุดรับสินค้า (หมุด สีเขียว)
    pickupLocations.forEach((location, plates) {
      final label = plates.join(', ');
      markers.add(Marker(
          point: location,
          width: 100,
          height: 80,
          child: _buildMarkerWithLabel(
            position: location,
            label: label,
            icon: Icons.location_on,
            iconColor: Colors.green, // änner สีเขียวสำหรับจุดรับ
          )));
    });

    // 6. สร้าง Marker สำหรับตำแหน่งจุดส่งสินค้า (หมุด สีแดง)
    destinationLocations.forEach((location, plates) {
      final label = plates.join(', ');
      markers.add(Marker(
          point: location,
          width: 100,
          height: 80,
          child: _buildMarkerWithLabel(
            position: location,
            label: label,
            icon: Icons.location_on,
            iconColor: Colors.red, // änner สีแดงสำหรับจุดส่ง
          )));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: SizedBox(
          height: 300,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: packages.isNotEmpty &&
                      packages.first.riderLocation.latitude != 0.0
                  ? packages.first.riderLocation
                  : const latlong.LatLng(
                      16.4339, 102.8230), // Default Mahasarakham
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ),
    );
  }

  // --- (Widget อื่นๆ ไม่มีกํารเปลี่ยนแปลง) ---
  Widget _buildStepItem({
    required String title,
    required IconData iconData,
    required int stepIndex,
    required int currentStep,
  }) {
    Color iconColor;
    Color backgroundColor;
    Color textColor = Colors.black54;
    if (stepIndex == currentStep) {
      backgroundColor = Colors.white;
      iconColor = Colors.green;
      textColor = Colors.black;
    } else {
      backgroundColor = Colors.grey.withOpacity(0.5);
      iconColor = Colors.white;
    }
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
            child: Icon(iconData, size: 28, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9, color: textColor, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
                title: 'รอรับออเดอร์สินค้า',
                iconData: Icons.hourglass_top,
                stepIndex: 0,
                currentStep: currentStep,
              ),
              _buildStepItem(
                title: 'ไรเดอร์รับงาน',
                iconData: Icons.assignment_turned_in,
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
                iconData: Icons.check_circle,
                stepIndex: 3,
                currentStep: currentStep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerWithLabel({
    required latlong.LatLng position,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Icon(icon,
            color: iconColor,
            size: 40,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 5.0)]),
      ],
    );
  }

  Widget _buildRiderStatusBlock({
    required BuildContext context,
    required PackageInfo package,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildRiderInfoCard(
            context: context,
            package: package,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildStatusStepper(currentStep: package.currentStep),
        ),
      ],
    );
  }

  Widget _buildRiderInfoCard({
    required BuildContext context,
    required PackageInfo package,
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ชื่อ : ${package.riderName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('หมายเลขโทรศัพท์ : ${package.riderPhone}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('หมายเลขทะเบียนรถ : ${package.riderPlate}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DetailPage(packageId: package.id)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('รายละเอียด',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: Colors.black, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.black, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                const Text(
                  'สินค้าที่กำลังส่ง',
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
            break;
          case 1:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => HistoryPage()));
            break;
          case 2:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => MoreOptionsPage()));
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_filled), label: "หน้าแรก"),
        BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded), label: "ประวัติการส่งสินค้า"),
        BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded), label: "อื่นๆ"),
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
        size.width, size.height, size.width, size.height - borderRadius);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
