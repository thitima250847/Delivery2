import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/rider/HomePageRider.dart'; // ใช้เพื่อย้อนกลับไปหน้า Home
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map/flutter_map.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart'; 

class TrackingScreen extends StatefulWidget {
  final String packageId; // เพิ่มตัวแปรสำหรับรับ ID งาน
  const TrackingScreen({super.key, required this.packageId});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const Color primaryGreen = Color(0xFF98C21D);
  static const Color darkGreenText = Color(0xFF98C21D);
  static const Color kYellow = Color(0xFFEDE500);

  // ********** 1. ตัวแปรสำหรับ Map Controller และ GPS Tracking **********
  final MapController _mapController = MapController(); 
  StreamSubscription<Position>? _positionStreamSubscription;
  final ImagePicker _picker = ImagePicker();

  // ข้อมูลสถานะจาก Firebase
  String _currentPackageStatus = 'accepted';
  final int _selectedTabIndex = 0;

  // ********** 2. ตัวแปรสถานะสำหรับดึงข้อมูลงาน **********
  String _currentRiderAddress = 'กำลังระบุตำแหน่ง...';
  final latlong.LatLng _pickupLocation = const latlong.LatLng(14.0754, 100.6049); // Fallback
  final latlong.LatLng _dropoffLocation = const latlong.LatLng(14.0850, 100.6120); // Fallback
  latlong.LatLng _currentRiderLocation = const latlong.LatLng(14.0754, 100.6049); // ตำแหน่งเริ่มต้น

  // ข้อมูลผู้ส่ง (จาก sender_info)
  String _senderName = 'กำลังโหลด...';
  String _senderPhone = 'กำลังโหลด...';
  String _pickupAddress = 'กำลังโหลดที่อยู่รับ...'; // ที่อยู่รับสินค้า
  // ข้อมูลผู้รับ (จาก receiver_info)
  String _receiverName = 'กำลังโหลด...';
  String _receiverPhone = 'กำลังโหลด...';
  String _dropoffAddress = 'กำลังโหลดที่อยู่ส่ง...'; // ที่อยู่ส่งสินค้า

  // ข้อมูลสินค้า (จาก package_description, proof_image_url)
  String _productDescription = 'กำลังโหลด...';
  String _productImageUrl = "https://via.placeholder.com/80?text=Product";

  // รูปถ่ายยืนยัน
  String? _proofPhoto1Url;
  String? _proofPhoto2Url;

  @override
  void initState() {
    super.initState();
    _fetchPackageStatus();
    _startListeningToLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _updateRiderLocationInFirestore(latlong.LatLng location) async {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId == null) return;

    try {
      await FirebaseFirestore.instance.collection('packages').doc(widget.packageId).update({
        'rider_lat': location.latitude,
        'rider_lng': location.longitude,
        'last_location_update': Timestamp.now(),
      });
    } catch (e) {
      print("Error updating rider location: $e");
    }
  }

  // *** NEW: ฟังก์ชัน Reverse Geocoding เพื่อหาที่อยู่จากพิกัด ***
  Future<void> _reverseGeocodeRiderLocation(latlong.LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: "th_TH", // กำหนดให้ผลลัพธ์เป็นภาษาไทย
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // สร้างที่อยู่แบบย่อ
        final address = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        
        if (mounted) {
          setState(() {
            _currentRiderAddress = address.isEmpty ? "ไม่พบที่อยู่ (Lat: ${location.latitude.toStringAsFixed(4)})" : address;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentRiderAddress = 'ไม่สามารถระบุที่อยู่ได้';
        });
      }
      print("Error during reverse geocoding: $e");
    }
  }

  // *** ฟังก์ชัน: เริ่มติดตามตำแหน่ง GPS ของไรเดอร์ (Real-time) ***
  Future<void> _startListeningToLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง GPS')),
          );
        }
        return; 
      }
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        final newLocation = latlong.LatLng(position.latitude, position.longitude);
        
        _updateRiderLocationInFirestore(newLocation);
        
        setState(() {
          _currentRiderLocation = newLocation;
          _mapController.move(_currentRiderLocation, _mapController.camera.zoom); 
        });
        _reverseGeocodeRiderLocation(newLocation);
      }
    });
  }

  // ********** 3. ดึงสถานะปัจจุบันและข้อมูลทั้งหมดของ Package **********
  void _fetchPackageStatus() {
    FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.packageId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        setState(() {
          _currentPackageStatus = data['status'] ?? 'accepted';
          _proofPhoto1Url = data['proof_image_url_1'];
          _proofPhoto2Url = data['proof_image_url_2'];

          // ดึงข้อมูลตำแหน่งไรเดอร์ล่าสุด
          final riderLat = data['rider_lat'] as double?;
          final riderLng = data['rider_lng'] as double?;
          if (riderLat != null && riderLng != null) {
              _currentRiderLocation = latlong.LatLng(riderLat, riderLng);
              // เมื่อดึงพิกัดมาแล้ว ให้แปลงเป็นที่อยู่ทันที (เผื่อกรณีเข้ามาหน้าจอใหม่)
              _reverseGeocodeRiderLocation(_currentRiderLocation); 
          }

          // 1. ดึงข้อมูลผู้ส่ง/ผู้รับจาก Field Map
          final senderInfo = data['sender_info'] as Map<String, dynamic>? ?? {};
          final receiverInfo = data['receiver_info'] as Map<String, dynamic>? ?? {};

          // อัปเดตข้อมูลผู้ส่ง (ที่อยู่รับสินค้า)
          _senderName = senderInfo['name'] ?? 'ไม่ระบุ';
          _senderPhone = senderInfo['phone'] ?? 'ไม่ระบุ';
          _pickupAddress = senderInfo['address'] ?? 'ไม่ระบุสถานที่รับ';
          
          // อัปเดตข้อมูลผู้รับ (ที่อยู่ส่งสินค้า)
          _receiverName = receiverInfo['name'] ?? 'ไม่ระบุ';
          _receiverPhone = receiverInfo['phone'] ?? 'ไม่ระบุ';
          _dropoffAddress = receiverInfo['address'] ?? 'ไม่ระบุสถานที่ส่ง';

          // 2. ดึงข้อมูลสินค้า
          _productDescription = data['package_description'] ?? 'ไม่มีรายละเอียด';
          _productImageUrl = data['proof_image_url'] ?? "https://i.imgur.com/kS9YnSg.png";
        });
      }
    });
  }

  // ฟังก์ชันจำลองการตรวจสอบระยะทาง
  Future<bool> _isWithinDistance(latlong.LatLng target) async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _currentRiderLocation = latlong.LatLng(position.latitude, position.longitude);
      });
      _reverseGeocodeRiderLocation(_currentRiderLocation); // อัปเดตที่อยู่ปัจจุบัน
      
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        target.latitude,
        target.longitude,
      );

      print("Current Distance to Target: $distanceInMeters meters");
      return distanceInMeters <= 20.0;
    } catch (e) {
      print("Error checking distance: $e");
      return false;
    }
  }

  // ฟังก์ชันสำหรับกด "รับสินค้าแล้ว" หรือ "นำส่งสินค้าแล้ว"
  Future<void> _updateStatus(String newStatus) async {
    if (!mounted) return;

    latlong.LatLng targetLocation;
    String statusCheck;

    if (_currentPackageStatus == 'accepted' && newStatus == 'on_delivery') {
      targetLocation = _pickupLocation; // ตรวจสอบที่จุดรับ
      statusCheck = 'รับสินค้า';
    } else if (_currentPackageStatus == 'on_delivery' && newStatus == 'delivered') {
      targetLocation = _dropoffLocation; // ตรวจสอบที่จุดส่ง
      statusCheck = 'นำส่งสินค้า';

      if (_proofPhoto1Url == null || _proofPhoto2Url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาถ่ายรูปยืนยันการจัดส่ง 2 รูปก่อน'), backgroundColor: Colors.orange),
        );
        return;
      }
    } else {
      return;
    }

    final isNear = await _isWithinDistance(targetLocation);

    if (!isNear) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('คุณอยู่ห่างจากจุด $statusCheck เกิน 20 เมตร'), backgroundColor: Colors.red),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.packageId)
        .update({'status': newStatus});

    if (newStatus == 'delivered') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งสินค้าสำเร็จ! คุณสามารถรับงานใหม่ได้แล้ว'), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePageRider()),
        (route) => false,
      );
    }
  }

  Future<void> _mockTakeAndUploadPhoto(int index) async {
    final XFile? xFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);

    if (xFile == null) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ยกเลิกการถ่ายภาพ'), backgroundColor: Colors.grey),
            );
        }
        return;
    }
    
    final mockUrl = "https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200"; 
    
    String field = index == 1 ? 'proof_image_url_1' : 'proof_image_url_2';
    FirebaseFirestore.instance.collection('packages').doc(widget.packageId).update({
      field: mockUrl,
    });
    
    setState(() {
      if (index == 1) {
        _proofPhoto1Url = mockUrl;
      } else {
        _proofPhoto2Url = mockUrl;
      }
    });

    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ถ่ายรูปยืนยันรูปที่ $index สำเร็จ (Mock Upload)')),
        );
    }
  }

  // ---------------------------------------------------------------------
  // WIDGET BUILDERS
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    int activeStep = 1;
    bool isDelivery = false;
    if (_currentPackageStatus == 'accepted') activeStep = 2; 
    if (_currentPackageStatus == 'on_delivery') {
      activeStep = 3; 
      isDelivery = true;
    }
    if (_currentPackageStatus == 'delivered') activeStep = 4; 

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(activeStep, isDelivery),
            const SizedBox(height: 24.0),
            _buildMap(), // Map แสดงตำแหน่ง Real-time
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 8),
            _buildTabContent(), // เปลี่ยนตามสถานะปัจจุบัน
            _buildSectionTitle("ข้อมูลสินค้า"),
            const SizedBox(height: 16),
            _buildProductCard(), // *ใช้ข้อมูลสินค้าจริง*
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int activeStep, bool isDelivery) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: const BoxDecoration(color: kYellow),
      child: Stack(
        children: [
          Column(
            children: [
              _buildPageTitle("สถานะการจัดส่งสินค้า"),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildStepItem(
                      Icons.hourglass_top_rounded,
                      "รอรับออเดอร์สินค้า",
                      activeStep >= 1,
                    ),
                    _buildStepConnector(activeStep >= 2),
                    _buildStepItem(
                      Icons.assignment_turned_in_outlined,
                      "ไรเดอร์รับงาน",
                      activeStep >= 2,
                    ),
                    _buildStepConnector(activeStep >= 3),
                    _buildStepItem(
                      Icons.delivery_dining_outlined,
                      "กำลังเดินทางส่งสินค้า",
                      activeStep >= 3,
                    ),
                    _buildStepConnector(activeStep >= 4),
                    _buildStepItem(
                      Icons.check_circle_outline_rounded,
                      "ส่งสินค้าเสร็จสิ้น",
                      activeStep >= 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
              onPressed: () {
                if (_currentPackageStatus == 'delivered') {
                   Navigator.of(context).pop();
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('กรุณาส่งงานปัจจุบันให้เสร็จสิ้นก่อน'), backgroundColor: Colors.red),
                   );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: kYellow,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String label, bool isActive) {
    final Color color = isActive ? darkGreenText : Colors.grey.shade400;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 3,
            color: isActive ? darkGreenText : Colors.grey.shade400,
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: darkGreenText,
          fontSize: 16,
        ),
      ),
    );
  }

// ---------------------------------------------------------------------

  Widget _buildMap() {
    final initialCenter = _currentRiderLocation.latitude != 0 || _currentRiderLocation.longitude != 0
        ? _currentRiderLocation
        : _pickupLocation; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: SizedBox(
          height: 250,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.delivery.riderapp', 
              ),
              MarkerLayer(
                markers: [
                  // 2.1 Rider Marker (สีแดง) - แสดงตำแหน่งปัจจุบัน
                  Marker(
                    point: _currentRiderLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.two_wheeler,
                      color: Color.fromARGB(255, 255, 0, 0), // สีแดงสด
                      size: 30,
                    ),
                  ),
                  // 2.2 Pickup Marker (สีแดงเข้ม/จุดเริ่มต้น)
                  Marker(
                    point: _pickupLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.deepOrange, // สีส้มแดง
                      size: 40,
                    ),
                  ),
                  // 2.3 Dropoff Marker (สีเขียว/จุดหมาย)
                  Marker(
                    point: _dropoffLocation,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: darkGreenText,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTabItem("สถานะกำลังส่ง", 0, _currentPackageStatus != 'delivered'),
          const SizedBox(width: 10),
          _buildTabItem("นำส่งสินค้าแล้ว", 1, _currentPackageStatus == 'delivered'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, bool isActive) {
    final color = isActive ? darkGreenText : Colors.grey.shade400;
    final fontWeight = isActive ? FontWeight.bold : FontWeight.normal;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? darkGreenText : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: fontWeight,
            fontSize: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAction() {
    if (_currentPackageStatus == 'accepted') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus('on_delivery'),
          icon: const Icon(Icons.two_wheeler, color: Colors.black),
          label: const Text('รับสินค้าแล้ว (เริ่มเดินทางไปส่ง)', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kYellow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    } else if (_currentPackageStatus == 'on_delivery') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus('delivered'),
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: const Text('นำส่งสินค้าสำเร็จ', style: TextStyle(color: Colors.white, fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: darkGreenText,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildTabContent() {
    if (_currentPackageStatus != 'delivered') {
      return Column(
        children: [
          _buildRiderLocationCard(), // แสดงที่อยู่ปัจจุบันของ Rider
          const SizedBox(height: 16),
          _buildPhotoUploaders(),
          const SizedBox(height: 16),
          _buildDeliveryAction(),
          const SizedBox(height: 16),
          _buildAddressCard(), // ที่อยู่จุดรับ/ส่ง
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: darkGreenText, size: 60),
              const SizedBox(height: 8),
              const Text(
                "นำส่งสินค้าสำเร็จแล้ว",
                style: TextStyle(color: darkGreenText, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildCompletedPhoto(_proofPhoto1Url),
                    const SizedBox(width: 16),
                    _buildCompletedPhoto(_proofPhoto2Url),
                  ],
                ),
              )
            ],
        ),
      ),
    );
    }
  }

  Widget _buildCompletedPhoto(String? imageUrl) {
      return Expanded(
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            image: DecorationImage(
              image: NetworkImage(imageUrl ?? "https://via.placeholder.com/110?text=No+Image"),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
  }

  Widget _buildPhotoUploaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildPhotoPlaceholder(
            _proofPhoto1Url,
            "รูปที่ 1 (มุมกว้าง)",
            () => _mockTakeAndUploadPhoto(1),
          ),
          const SizedBox(width: 16),
          _buildPhotoPlaceholder(
            _proofPhoto2Url,
            "รูปที่ 2 (สินค้า)",
            () => _mockTakeAndUploadPhoto(2),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String? imageUrl, String label, VoidCallback onCameraTap) {
    return Expanded(
      child: InkWell(
        onTap: _currentPackageStatus == 'on_delivery' && imageUrl == null ? onCameraTap : null,
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: imageUrl != null ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
            ],
            image: imageUrl != null
                ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                : null,
          ),
          child: imageUrl == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: primaryGreen, size: 35),
                    const SizedBox(height: 4),
                    Text(label, style: const TextStyle(fontSize: 12, color: primaryGreen)),
                  ],
                )
              : Container(),
        ),
      ),
    );
  }
  
  Widget _buildRiderLocationCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.my_location_rounded, color: Colors.blue, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📍 ที่อยู่ปัจจุบันของคุณ (Rider)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentRiderAddress, // *** แสดงที่อยู่ปัจจุบันของ Rider ***
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAddressCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ********** ที่อยู่รับสินค้า (Pickup) **********
            _buildAddressInfo(
                icon: Icons.location_on,
                iconColor: Colors.red,
                title: "จุดรับสินค้า (ผู้ส่ง): $_pickupAddress",
                name: _senderName,
                phone: _senderPhone,
                labelPrefix: "ชื่อผู้ส่ง",
              ),
            const Divider(height: 32, color: Colors.grey),
            // ********** ที่อยู่ส่งสินค้า (Dropoff) **********
            _buildAddressInfo(
                icon: Icons.location_on,
                iconColor: darkGreenText,
                title: "จุดส่งสินค้า (ผู้รับ): $_dropoffAddress",
                name: _receiverName,
                phone: _receiverPhone,
                labelPrefix: "ชื่อผู้รับ",
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String phone,
    required String labelPrefix,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                "$labelPrefix : $name",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "เบอร์โทรศัพท์ : $phone",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                _productImageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "รายละเอียดสินค้า:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _productDescription,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
