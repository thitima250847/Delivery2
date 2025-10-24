import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:http/http.dart' as http;

class OrderMapsPage extends StatefulWidget {
  final String packageId;

  const OrderMapsPage({super.key, required this.packageId});

  @override
  _OrderMapsPageState createState() => _OrderMapsPageState();
}

class _OrderMapsPageState extends State<OrderMapsPage> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String? _errorMessage;

  latlong.LatLng? _pickupLocation;
  latlong.LatLng? _dropoffLocation;
  final List<latlong.LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _fetchPackageAndRouteDetails();
  }

  Future<void> _fetchPackageAndRouteDetails() async {
    try {
      // 1. ดึงข้อมูลพิกัดจาก Firestore
      final doc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception("ไม่พบข้อมูลออเดอร์");
      }

      final data = doc.data()!;
      final senderInfo = (data['sender_info'] as Map<String, dynamic>?) ?? {};
      final receiverInfo = (data['receiver_info'] as Map<String, dynamic>?) ?? {};

      final pickupLat = (senderInfo['lat'] as num?)?.toDouble();
      final pickupLng = (senderInfo['lng'] as num?)?.toDouble();
      final dropoffLat = (receiverInfo['lat'] as num?)?.toDouble();
      final dropoffLng = (receiverInfo['lng'] as num?)?.toDouble();

      if (pickupLat == null || pickupLng == null || dropoffLat == null || dropoffLng == null) {
        throw Exception("ข้อมูลพิกัดไม่สมบูรณ์");
      }

      _pickupLocation = latlong.LatLng(pickupLat, pickupLng);
      _dropoffLocation = latlong.LatLng(dropoffLat, dropoffLng);

      // 2. เรียก API เพื่อดึงเส้นทาง
      await _fetchRoute();

    } catch (e) {
      setState(() {
        _errorMessage = "เกิดข้อผิดพลาด: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_pickupLocation == null || _dropoffLocation == null) return;
    
    // ใช้ Openrouteservice API (ต้องสมัครและรับ Key ฟรี)
    // *** กรุณาใส่ API Key ของคุณเองที่นี่ ***
    const String apiKey = 'YOUR_OPENROUTESERVICE_API_KEY';
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car'
        '?api_key=$apiKey'
        '&start=${_pickupLocation!.longitude},${_pickupLocation!.latitude}'
        '&end=${_dropoffLocation!.longitude},${_dropoffLocation!.latitude}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints.clear();
          for (var coord in coordinates) {
            _routePoints.add(latlong.LatLng(coord[1], coord[0]));
          }
        });
      } else {
        // จัดการกรณี API Error
        print("API Error: ${response.body}");
      }
    } catch(e) {
      print("Error fetching route: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่เส้นทาง'),
        backgroundColor: const Color(0xFFF0DB0C), // สีเหลืองเหมือนหน้า Rider Home
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildMapContent(),
    );
  }

  Widget _buildMapContent() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      return const Center(child: Text("ไม่พบข้อมูลพิกัด"));
    }

    // คำนวณขอบเขตของแผนที่ให้เห็นทั้งสองจุด
    final bounds = LatLngBounds.fromPoints([_pickupLocation!, _dropoffLocation!]);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0), // เพิ่มระยะขอบ
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        // ชั้นสำหรับวาดเส้นทาง
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              strokeWidth: 5.0,
              color: Colors.blue,
            ),
          ],
        ),
        // ชั้นสำหรับแสดง Marker
        MarkerLayer(
          markers: [
            // Marker จุดรับสินค้า
            Marker(
              point: _pickupLocation!,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.store,
                color: Color.fromARGB(255, 0, 60, 255),
                size: 40,
              ),
            ),
            // Marker จุดส่งสินค้า
            Marker(
              point: _dropoffLocation!,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Color.fromARGB(255, 255, 0, 0),
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}