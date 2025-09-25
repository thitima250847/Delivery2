// lib/map_picker_screen.dart (ฉบับเขียนใหม่ทั้งหมดสำหรับ Thunderforest)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong; // ใช้ as latlong เพื่อไม่ให้ชื่อซ้ำกับ library อื่น
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => MapPickerScreenState();
}

class MapPickerScreenState extends State<MapPickerScreen> {
  // Controller สำหรับควบคุมแผนที่ของ flutter_map
  final MapController _mapController = MapController();
  
  // ตัวแปรสำหรับเก็บตำแหน่งที่ผู้ใช้เลือก
  latlong.LatLng? _pickedLocation;

  // ตำแหน่งเริ่มต้น (กรุงเทพฯ) ใช้ในกรณีที่ดึงตำแหน่งปัจจุบันไม่ได้
  final latlong.LatLng _initialPosition =
      const latlong.LatLng(13.7563, 100.5018);

  @override
  void initState() {
    super.initState();
    // เรียกใช้ฟังก์ชันเพื่อดึงตำแหน่งปัจจุบันเมื่อหน้าจอถูกสร้างขึ้น
    _getCurrentLocationAndMoveCamera();
  }

  // ฟังก์ชันสำหรับขออนุญาตและดึงตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocationAndMoveCamera() async {
    try {
      // 1. ตรวจสอบและขออนุญาตการเข้าถึงตำแหน่ง
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง'),
            ));
          }
          return;
        }
      }

      // 2. ดึงตำแหน่งปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation =
          latlong.LatLng(position.latitude, position.longitude);

      // 3. ย้ายแผนที่ไปยังตำแหน่งปัจจุบันและปักหมุด
      _mapController.move(currentLocation, 16.0); // 16.0 คือระดับการซูม
      setState(() {
        _pickedLocation = currentLocation;
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  // ฟังก์ชันที่จะทำงานเมื่อผู้ใช้แตะบนแผนที่
  void _onMapTapped(TapPosition tapPosition, latlong.LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
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
                // ‼️ สำคัญ: นำ API Key จาก Thunderforest Console มาใส่ตรงนี้ ‼️
                urlTemplate:
                    'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=2d1b06685c2b44b98e32ef3a085ca2ca',
                userAgentPackageName: 'com.example.delivery', // <-- อาจจะต้องเปลี่ยนเป็น package name ของแอปคุณ
              ),
              // แสดง Marker ถ้ามีตำแหน่งที่ถูกเลือกแล้ว
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
          // ปุ่มยืนยันตำแหน่ง
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('ยืนยันตำแหน่งนี้',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              onPressed: _pickedLocation == null
                  ? null
                  : () {
                      // ส่งค่าพิกัดกลับไปหน้า registerUser
                      Navigator.of(context).pop(_pickedLocation);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}