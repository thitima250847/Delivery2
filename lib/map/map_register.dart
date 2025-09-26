import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => MapPickerScreenState();
}

class MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();

  latlong.LatLng? _pickedLocation;
  String? _pickedAddress;

  final latlong.LatLng _initialPosition = const latlong.LatLng(
    13.7563,
    100.5018,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndMoveCamera();
  }

  // ดึงตำแหน่งปัจจุบันและย้ายกล้อง
  Future<void> _getCurrentLocationAndMoveCamera() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง')),
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = latlong.LatLng(
        position.latitude,
        position.longitude,
      );

      _mapController.move(currentLocation, 16.0);

      // ดึงที่อยู่จากตำแหน่งปัจจุบัน
      _updatePickedLocation(currentLocation);
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  // อัปเดตตำแหน่งและดึงชื่อที่อยู่
  Future<void> _updatePickedLocation(latlong.LatLng location) async {
    setState(() {
      _pickedLocation = location;
      _pickedAddress = 'กำลังค้นหาที่อยู่...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: 'th_TH',
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.subThoroughfare, // บ้านเลขที่
          placemark.thoroughfare, // ถนน
          placemark.subLocality, // ตำบล/แขวง
          placemark.locality, // อำเภอ/เขต
          placemark.administrativeArea, // จังหวัด
          placemark.postalCode, // รหัสไปรษณีย์
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _pickedAddress = address;
        });
      } else {
        setState(() {
          _pickedAddress = 'ไม่พบข้อมูลที่อยู่';
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        _pickedAddress = 'เกิดข้อผิดพลาดในการค้นหาที่อยู่';
      });
    }
  }

  // ฟังก์ชันเรียกเมื่อแตะแผนที่
  void _onMapTapped(TapPosition tapPosition, latlong.LatLng location) {
    _updatePickedLocation(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตำแหน่งบนแผนที่'),
        backgroundColor: const Color(0xFFFEE600),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.0,
              onTap: _onMapTapped,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=2d1b06685c2b44b98e32ef3a085ca2ca',
                userAgentPackageName: 'com.example.delivery',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // กล่องแสดงที่อยู่
          if (_pickedAddress != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickedAddress!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ปุ่มยืนยันตำแหน่ง
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'ยืนยันตำแหน่งนี้',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: _pickedLocation == null || _pickedAddress == null
                  ? null
                  : () {
                      Navigator.of(context).pop({
                        'location': _pickedLocation,
                        'address': _pickedAddress,
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
