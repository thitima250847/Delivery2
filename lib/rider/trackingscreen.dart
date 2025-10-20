import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

import 'package:image_picker/image_picker.dart' as xpicker;
import 'package:cloudinary_public/cloudinary_public.dart';

import 'package:delivery/rider/HomePageRider.dart';

class TrackingScreen extends StatefulWidget {
  final String packageId;
  const TrackingScreen({super.key, required this.packageId});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // สีหลัก
  static const Color primaryGreen = Color(0xFF98C21D);
  static const Color darkGreenText = Color(0xFF98C21D);
  static const Color kYellow = Color(0xFFEDE500);

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;

  // กล้อง
  final xpicker.ImagePicker _picker = xpicker.ImagePicker();

  // Cloudinary
  final cloudinary = CloudinaryPublic('dwltvhlju', 'delivery', cache: false);

  // สถานะ
  String _currentPackageStatus = 'accepted';
  bool _isLoading = false;

  // ตำแหน่ง
  latlong.LatLng _currentRiderLocation = const latlong.LatLng(0, 0);
  latlong.LatLng _pickupLocation = const latlong.LatLng(0, 0);
  latlong.LatLng _dropoffLocation = const latlong.LatLng(0, 0);

  // ข้อมูล
  String _senderName = 'กำลังโหลด...';
  String _senderPhone = 'กำลังโหลด...';
  String _pickupAddress = 'กำลังโหลด...';
  String _receiverName = 'กำลังโหลด...';
  String _receiverPhone = 'กำลังโหลด...';
  String _dropoffAddress = 'กำลังโหลด...';
  String _productDescription = 'กำลังโหลด...';
  String _productImageUrl = "https://i.imgur.com/kS9YnSg.png";

  // หลักฐานรูป
  String? _proofPhoto1Url;
  String? _proofPhoto2Url;
  xpicker.XFile?
      _localProofPhoto1; // <-- ตัวแปรใหม่สำหรับเก็บรูปที่ถ่ายชั่วคราว

  @override
  void initState() {
    super.initState();
    _fetchPackageDetails();
    _startListeningToLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // ----- LOCATION (เหมือนเดิม) -----
  Future<void> _updateRiderLocationInFirestore(latlong.LatLng location) async {
    try {
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .update({
        'rider_lat': location.latitude,
        'rider_lng': location.longitude,
        'last_location_update': Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Error updating rider location: $e");
    }
  }

  Future<void> _startListeningToLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (!mounted) return;
      final newLocation = latlong.LatLng(position.latitude, position.longitude);
      _updateRiderLocationInFirestore(newLocation);
      setState(() {
        _currentRiderLocation = newLocation;
        _mapController.move(_currentRiderLocation, _mapController.camera.zoom);
      });
    });
  }

  // ----- FIRESTORE (เหมือนเดิม) -----
  void _fetchPackageDetails() {
    FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.packageId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;
      final data = snapshot.data()!;
      if (!mounted) return;

      setState(() {
        _currentPackageStatus = data['status'] ?? 'accepted';
        _proofPhoto1Url = data['proof_image_url_1'];
        _proofPhoto2Url = data['proof_image_url_2'];

        final senderInfo = (data['sender_info'] as Map<String, dynamic>?) ?? {};
        final receiverInfo =
            (data['receiver_info'] as Map<String, dynamic>?) ?? {};

        _senderName = senderInfo['name'] ?? 'ไม่ระบุ';
        _senderPhone = senderInfo['phone'] ?? 'ไม่ระบุ';
        _pickupAddress = senderInfo['address'] ?? 'ไม่ระบุ';

        _receiverName = receiverInfo['name'] ?? 'ไม่ระบุ';
        _receiverPhone = receiverInfo['phone'] ?? 'ไม่ระบุ';
        _dropoffAddress = receiverInfo['address'] ?? 'ไม่ระบุ';

        _productDescription = data['package_description'] ?? 'ไม่มีรายละเอียด';
        _productImageUrl =
            data['proof_image_url'] ?? "https://i.imgur.com/kS9YnSg.png";

        _pickupLocation = latlong.LatLng(
          (senderInfo['lat'] as num?)?.toDouble() ?? 0.0,
          (senderInfo['lng'] as num?)?.toDouble() ?? 0.0,
        );
        _dropoffLocation = latlong.LatLng(
          (receiverInfo['lat'] as num?)?.toDouble() ?? 0.0,
          (receiverInfo['lng'] as num?)?.toDouble() ?? 0.0,
        );
      });
    });
  }

  // ----- PHOTO & STATUS UPDATE (เหมือนเดิม) -----
  Future<void> _takePhotoForPickup() async {
    final xpicker.XFile? imageFile = await _picker.pickImage(
      source: xpicker.ImageSource.camera,
      imageQuality: 80,
    );
    if (imageFile == null) return;
    setState(() {
      _localProofPhoto1 = imageFile;
    });
  }

  Future<void> _takeAndUploadPhotoForDropoff() async {
    final xpicker.XFile? imageFile = await _picker.pickImage(
      source: xpicker.ImageSource.camera,
      imageQuality: 80,
    );
    if (imageFile == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path),
      );
      final imageUrl = res.secureUrl;
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .update({'proof_image_url_2': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('อัปโหลดรูปที่ 2 สำเร็จ'),
              backgroundColor: Colors.green),
        );
      }
    } on CloudinaryException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('อัปโหลดรูปภาพล้มเหลว: ${e.message}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      if (newStatus == 'on_delivery') {
        if (_localProofPhoto1 == null) {
          throw Exception('กรุณาถ่ายรูปยืนยันการรับสินค้าก่อน');
        }
        final res = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(_localProofPhoto1!.path),
        );
        final imageUrl = res.secureUrl;

        await FirebaseFirestore.instance
            .collection('packages')
            .doc(widget.packageId)
            .update({
          'status': newStatus,
          'proof_image_url_1': imageUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('รับสินค้าเรียบร้อย เริ่มเดินทาง!'),
                backgroundColor: Colors.green),
          );
        }
      } else if (newStatus == 'delivered') {
        if (_proofPhoto2Url == null) {
          throw Exception('กรุณาถ่ายรูปยืนยันการส่งสินค้าก่อน');
        }
        await FirebaseFirestore.instance
            .collection('packages')
            .doc(widget.packageId)
            .update({
          'status': newStatus,
          'delivered_at': Timestamp.now(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ส่งสินค้าสำเร็จ!'), backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePageRider()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().contains("Exception:")
            ? e.toString().replaceFirst("Exception: ", "")
            : 'เกิดข้อผิดพลาด: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ====================== UI ======================

  @override
  Widget build(BuildContext context) {
    int activeStep;
    switch (_currentPackageStatus) {
      case 'accepted':
        activeStep = 2;
        break;
      case 'on_delivery':
        activeStep = 3;
        break;
      case 'delivered':
        activeStep = 4;
        break;
      default:
        activeStep = 1;
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(activeStep),
                const SizedBox(height: 24.0),
                _buildMap(),
                const SizedBox(height: 16),
                _buildTabBar(),
                const SizedBox(height: 8),
                _buildTabContent(),
                _buildSectionTitle("ข้อมูลผู้ติดต่อและที่อยู่"),
                const SizedBox(height: 16),
                _buildAddressCard(),
                _buildSectionTitle("ข้อมูลสินค้า"),
                const SizedBox(height: 16),
                _buildProductCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: kYellow),
              ),
            ),
        ],
      ),
    );
  }

  // ----- Map (ปรับปรุง) -----
  Widget _buildMap() {
    // สร้างลิสต์ของ Markers
    List<Marker> markers = [];

    // 1. เพิ่ม Marker ของไรเดอร์เสมอ
    if (_currentRiderLocation.latitude != 0.0) {
      markers.add(
        Marker(
          point: _currentRiderLocation,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.two_wheeler,
            color: Colors.blue,
            size: 30,
          ),
        ),
      );
    }

    // 2. เช็คก่อนว่ามีพิกัดจุดรับหรือไม่ ถ้ามีถึงจะเพิ่ม Marker
    if (_pickupLocation.latitude != 0.0 && _pickupLocation.longitude != 0.0) {
      markers.add(
        Marker(
          point: _pickupLocation,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    // 3. เช็คก่อนว่ามีพิกัดจุดส่งหรือไม่ ถ้ามีถึงจะเพิ่ม Marker (ถูกต้องอยู่แล้ว)
    if (_dropoffLocation.latitude != 0.0 && _dropoffLocation.longitude != 0.0) {
      markers.add(
        Marker(
          point: _dropoffLocation,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: darkGreenText,
            size: 40,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: SizedBox(
          height: 250,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentRiderLocation.latitude != 0.0
                  ? _currentRiderLocation
                  : const latlong.LatLng(
                      16.4339, 102.8230), // Default Mahasarakham
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              // ใช้ Markers ที่สร้างและกรองแล้ว
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ),
    );
  }

  // --- (Widget ที่เหลือเหมือนเดิม) ---
  Widget _buildHeader(int activeStep) {
    bool isActive(int step) => activeStep == step;
    bool connectorOnBefore(int step) => activeStep > step;
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
                        Icons.hourglass_top, "รอรับออเดอร์", isActive(1)),
                    _buildStepConnector(connectorOnBefore(1)),
                    _buildStepItem(Icons.assignment_turned_in, "ไรเดอร์รับงาน",
                        isActive(2)),
                    _buildStepConnector(connectorOnBefore(2)),
                    _buildStepItem(
                        Icons.delivery_dining, "กำลังเดินทาง", isActive(3)),
                    _buildStepConnector(connectorOnBefore(3)),
                    _buildStepItem(
                        Icons.check_circle, "ส่งเสร็จสิ้น", isActive(4)),
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
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePageRider()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
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
            color: isActive ? darkGreenText : Colors.grey.shade300,
          ),
          const SizedBox(height: 42),
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
          color: darkGreenText,
          fontSize: 18,
        ),
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

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTabItem(
              "สถานะกำลังส่ง", 0, _currentPackageStatus != 'delivered'),
          const SizedBox(width: 10),
          _buildTabItem(
              "นำส่งสินค้าแล้ว", 1, _currentPackageStatus == 'delivered'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, bool isActive) {
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
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
            color: isActive ? darkGreenText : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_currentPackageStatus != 'delivered') {
      return Column(
        children: [
          _buildPhotoUploaders(),
          const SizedBox(height: 24),
          _buildDeliveryAction(),
          const SizedBox(height: 16),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: darkGreenText, size: 60),
              const SizedBox(height: 8),
              const Text(
                "นำส่งสินค้าสำเร็จแล้ว",
                style: TextStyle(
                    color: darkGreenText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildCompletedPhoto(_proofPhoto1Url),
                  const SizedBox(width: 16),
                  _buildCompletedPhoto(_proofPhoto2Url),
                ],
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
            image: NetworkImage(
                imageUrl ?? "https://via.placeholder.com/110?text=No+Image"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAction() {
    if (_currentPackageStatus == 'accepted') {
      final canPress = _localProofPhoto1 != null;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canPress ? () => _updateStatus('on_delivery') : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kYellow,
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'รับสินค้าแล้ว',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ),
      );
    } else if (_currentPackageStatus == 'on_delivery') {
      final canPress = _proofPhoto2Url != null;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canPress ? () => _updateStatus('delivered') : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreenText,
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'นำส่งสินค้าสำเร็จ',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPhotoUploaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildPhotoPlaceholder(
            localImageFile: _localProofPhoto1,
            imageUrl: _proofPhoto1Url,
            label: "ถ่ายรูป ณ จุดรับ",
            onCameraTap: _takePhotoForPickup,
            canTap: _proofPhoto1Url == null &&
                _localProofPhoto1 == null &&
                _currentPackageStatus == 'accepted',
          ),
          const SizedBox(width: 16),
          _buildPhotoPlaceholder(
            imageUrl: _proofPhoto2Url,
            label: "ถ่ายรูป ณ จุดส่ง",
            onCameraTap: _takeAndUploadPhotoForDropoff,
            canTap: _proofPhoto2Url == null &&
                _currentPackageStatus == 'on_delivery',
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder({
    String? imageUrl,
    xpicker.XFile? localImageFile,
    required String label,
    required VoidCallback onCameraTap,
    required bool canTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: canTap ? onCameraTap : null,
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(color: Colors.grey.shade300),
            image: localImageFile != null
                ? DecorationImage(
                    image: FileImage(File(localImageFile.path)),
                    fit: BoxFit.cover)
                : imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
          ),
          child: (imageUrl == null && localImageFile == null)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        color: canTap ? primaryGreen : Colors.grey, size: 40),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: canTap ? primaryGreen : Colors.grey)),
                  ],
                )
              : null,
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
            _buildAddressInfo(
              icon: Icons.location_on,
              iconColor: Colors.red,
              title: "จุดรับสินค้า (ผู้ส่ง): $_pickupAddress",
              name: _senderName,
              phone: _senderPhone,
              labelPrefix: "ชื่อผู้ส่ง",
            ),
            const Divider(height: 32, color: Colors.grey),
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
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text("$labelPrefix : $name",
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text("เบอร์โทรศัพท์ : $phone",
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("รายละเอียดสินค้า:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_productDescription,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
