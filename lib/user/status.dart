// status.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/user/status_detail.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

// หน้าหลักอื่นๆ
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, required packageId});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  static const Color primaryYellow = Color(0xFFFDE100);

  final Map<String, Map<String, dynamic>> _riderCache = {};
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _allPackagesStream;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _navIndex = 0;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final baseCol = FirebaseFirestore.instance.collection('packages');
    final Query<Map<String, dynamic>> q = (_currentUserId.isEmpty)
        ? baseCol.where('status',
            whereIn: ['pending', 'accepted', 'on_delivery', 'delivered'])
        : baseCol.where('receiver_user_id', isEqualTo: _currentUserId).where(
            'status',
            whereIn: ['pending', 'accepted', 'on_delivery', 'delivered']);
    _allPackagesStream = q.snapshots();
  }

  String _str(dynamic v) => (v == null) ? '' : v.toString();

  Map<String, dynamic> _normalizeRider(Map<String, dynamic> riderDoc,
      {Map<String, dynamic>? fromPackage}) {
    return {
      'name': _str(riderDoc['name']),
      'phone_number': _str(riderDoc['phone_number']),
      'license_plate': _str(riderDoc['license_plate']),
    };
  }

  // VVVVVV เพิ่ม: ฟังก์ชันสำหรับดึงข้อมูลไรเดอร์ทั้งหมดก่อนสร้าง UI VVVVVV
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _fetchRidersForPackages(
          List<QueryDocumentSnapshot<Map<String, dynamic>>> packages) async {
    List<Future> riderFutures = [];
    for (var doc in packages) {
      final data = doc.data();
      final riderId = data['rider_id'] as String?;
      if (riderId != null && !_riderCache.containsKey(riderId)) {
        riderFutures.add(FirebaseFirestore.instance
            .collection('riders')
            .doc(riderId)
            .get()
            .then((riderDoc) {
          if (riderDoc.exists) {
            _riderCache[riderId] = _normalizeRider(riderDoc.data()!);
          }
        }));
      }
    }
    await Future.wait(riderFutures);
    return packages;
  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        toolbarHeight: 90.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "รายการสินค้าที่ต้องรับ",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _allPackagesStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: primaryYellow));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่มีรายการสินค้าที่ต้องรับ'));
          }

          var allDocs = snap.data!.docs;

          // VVVVVV ใช้ FutureBuilder ครอบเพื่อรอข้อมูลไรเดอร์ VVVVVV
          return FutureBuilder<
              List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            future: _fetchRidersForPackages(allDocs),
            builder: (context, processedSnap) {
              if (processedSnap.connectionState != ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator(color: primaryYellow));
              }

              var packages = processedSnap.data!;
              if (packages.isEmpty) {
                return const Center(
                    child: Text('ไม่พบรายการที่กำลังดำเนินการ'));
              }

              int statusSortOrder(String status) {
                switch (status) {
                  case 'on_delivery':
                    return 0;
                  case 'accepted':
                    return 1;
                  case 'pending':
                    return 2;
                  case 'delivered':
                    return 3;
                  default:
                    return 4;
                }
              }

              packages.sort((a, b) {
                final statusA = a.data()['status'] as String? ?? 'pending';
                final statusB = b.data()['status'] as String? ?? 'pending';
                return statusSortOrder(statusA)
                    .compareTo(statusSortOrder(statusB));
              });

              return Column(
                children: [
                  _buildMultiRiderMap(packages),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: packages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final d = packages[i];
                        return _buildListItem(d);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // VVVVVV แก้ไข: เอา FutureBuilder ด้านในออก VVVVVV
  Widget _buildListItem(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final packageId = d.id;
    final status = data['status'] as String? ?? 'pending';
    final senderInfo = data['sender_info'] as Map<String, dynamic>? ?? {};
    final senderName = senderInfo['name'] as String? ?? 'ไม่มีชื่อผู้ส่ง';
    final senderPhone = senderInfo['phone'] as String? ?? 'ไม่มีเบอร์';
    final productImg = (data['proof_image_url'] as String?) ??
        'https-via.placeholder.com/160?text=No+Image';
    final riderId = data['rider_id'] as String?;

    // ดึงข้อมูลจาก Cache โดยตรง
    final rider = _riderCache[riderId] ?? {};
    final riderName = (rider['name'] as String?)?.isNotEmpty == true
        ? rider['name']
        : (riderId != null ? 'กำลังค้นหา...' : 'รอไรเดอร์');
    final riderPhone = (rider['phone_number'] as String?) ?? '—';
    final riderPlate = (rider['license_plate'] as String?) ?? '—';

    return _buildPackageListCard(
      packageId: packageId,
      imageUrl: productImg,
      status: status,
      senderName: senderName,
      senderPhone: senderPhone,
      riderName: riderName,
      riderPhone: riderPhone,
      riderPlate: riderPlate,
    );
  }

  Widget _buildMultiRiderMap(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> packages) {
    final Map<latlong.LatLng, List<String>> riderLocations = {};
    final Map<latlong.LatLng, List<String>> pickupLocations = {};
    latlong.LatLng? destinationLocation;

    if (packages.isNotEmpty) {
      final firstPackageData = packages.first.data();
      final receiverInfo =
          firstPackageData['receiver_info'] as Map<String, dynamic>? ?? {};
      final destLat = (receiverInfo['lat'] as num?)?.toDouble();
      final destLng = (receiverInfo['lng'] as num?)?.toDouble();
      if (destLat != null && destLng != null) {
        destinationLocation = latlong.LatLng(destLat, destLng);
      }
    }

    for (var doc in packages) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'pending';
      final riderId = data['rider_id'] as String?;

      // _riderCache มีข้อมูลครบแล้ว ดึงได้เลย
      final plate = _riderCache[riderId]?['license_plate'] ?? '...';

      if (status == 'on_delivery' &&
          (data['rider_lat'] != null && data['rider_lat'] != 0.0)) {
        final riderLat = (data['rider_lat'] as num).toDouble();
        final riderLng = (data['rider_lng'] as num).toDouble();
        final loc = latlong.LatLng(riderLat, riderLng);
        riderLocations.putIfAbsent(loc, () => []).add(plate);
      }

      if (status == 'accepted' || status == 'on_delivery') {
        final senderInfo = data['sender_info'] as Map<String, dynamic>? ?? {};
        final lat = (senderInfo['lat'] as num?)?.toDouble();
        final lng = (senderInfo['lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          final loc = latlong.LatLng(lat, lng);
          pickupLocations.putIfAbsent(loc, () => []).add(plate);
        }
      }
    }

    final List<Marker> markers = [];

    riderLocations.forEach((location, plates) {
      final label = plates
          .where((p) => p.isNotEmpty && p != '—' && p != '...')
          .toSet()
          .join(', ');
      markers.add(Marker(
          point: location,
          width: 100,
          height: 60,
          child: _buildMarkerWithLabel(
            label: label,
            icon: Icons.motorcycle,
            iconColor: Colors.blueAccent,
          )));
    });

    pickupLocations.forEach((location, plates) {
      final label = plates
          .where((p) => p.isNotEmpty && p != '—' && p != '...')
          .toSet()
          .join(', ');
      markers.add(Marker(
        point: location,
        width: 100,
        height: 60,
        child: _buildMarkerWithLabel(
          label: label,
          icon: Icons.store,
          iconColor: Colors.green,
        ),
      ));
    });

    if (destinationLocation != null) {
      markers.add(Marker(
          point: destinationLocation,
          width: 100,
          height: 60,
          child: _buildMarkerWithLabel(
            label: 'จุดรับของคุณ',
            icon: Icons.home,
            iconColor: Colors.purple,
          )));
    }

    return Container(
      height: 250,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                destinationLocation ?? const latlong.LatLng(16.4339, 102.8230),
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
    );
  }

  // --- (โค้ดส่วนที่เหลือไม่มีการเปลี่ยนแปลง) ---
  Widget _buildMarkerWithLabel({
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 4),
        Icon(icon,
            color: iconColor,
            size: 35,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 5.0)]),
      ],
    );
  }


  String _statusLabel(String s) {
    switch (s.toLowerCase().trim()) {
      case 'pending':
        return 'รอไรเดอร์รับงาน';
      case 'accepted':
        return 'ไรเดอร์รับงานแล้ว';
      case 'on_delivery':
        return 'กำลังจัดส่ง';
      case 'delivered':
        return 'จัดส่งสำเร็จ';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase().trim()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'accepted':
        return Colors.blue.shade700;
      case 'on_delivery':
        return Colors.deepPurple.shade600;
      case 'delivered':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPackageListCard({
    required String packageId,
    required String imageUrl,
    required String status,
    required String senderName,
    required String senderPhone,
    required String riderName,
    required String riderPhone,
    required String riderPlate,
  }) {
    final statusText = _statusLabel(status);
    final statusColor = _statusColor(status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StatusDetailScreen(packageId: packageId)),
        );
      },
      child: Card(
        color: status == 'delivered'
            ? Colors.grey[200]
            : const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: status == 'delivered' ? 1 : 3,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.inventory_2_outlined,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "#${packageId.substring(0, min(8, packageId.length))}",
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusTag(statusText, statusColor),
                    const SizedBox(height: 8),
                    const Text(
                      'ข้อมูลผู้ส่ง',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey),
                    ),
                    const Divider(height: 8),
                    _buildInfoRow(Icons.person_outline, senderName),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.phone_outlined, senderPhone),
                    const SizedBox(height: 12),
                    const Text(
                      'ข้อมูลไรเดอร์',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                    const Divider(height: 8),
                    _buildInfoRow(Icons.motorcycle_outlined, riderName),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.badge_outlined, riderPlate),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.phone_android_outlined, riderPhone),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
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
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DeliveryPage()));
            break;
          case 1:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HistoryPage()));
            break;
          case 2:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const MoreOptionsPage()));
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
