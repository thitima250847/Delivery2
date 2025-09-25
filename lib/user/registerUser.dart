// registerUser.dart

import 'dart:typed_data';

import 'package:delivery/map/map_register.dart';
import 'package:delivery/rider/registerRider.dart';
import 'package:delivery/user/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RegisterUser extends StatefulWidget {
  const RegisterUser({super.key});

  @override
  State<RegisterUser> createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {
  // controllers
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _addressCtl = TextEditingController(); // เก็บชื่อที่อยู่จาก MapPicker
  final _passwordCtl = TextEditingController();
  final _gpsCtl = TextEditingController(); // รูปแบบ "lat,lng"

  // image state
  final _picker = ImagePicker();
  Uint8List? _imageBytes; // preview

  bool _submitting = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _passwordCtl.dispose();
    _gpsCtl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (x == null) return;

      final bytes = await x.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
      });
    } catch (e) {
      _showSnack('เลือกรูปไม่สำเร็จ: $e');
    }
  }

  Future<String?> _uploadProfile(String uid) async {
    if (_imageBytes == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref('user_profiles/$uid.jpg');
      await ref.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      _showSnack('อัปโหลดรูปไม่สำเร็จ: $e');
      return null;
    }
  }

  // แยกชื่อสถานที่และพิกัดจาก String "ชื่อสถานที่ (lat, lng)"
  ({String? place, double? lat, double? lng}) _parseGps(String raw) {
    try {
      final regex = RegExp(r'^(.*)\s*\(([-\d.]+),\s*([-\d.]+)\)$');
      final match = regex.firstMatch(raw);
      if (match != null) {
        final place = match.group(1)?.trim();
        final lat = double.parse(match.group(2)!);
        final lng = double.parse(match.group(3)!);
        return (place: place, lat: lat, lng: lng);
      }
      return (place: null, lat: null, lng: null);
    } catch (_) {
      return (place: null, lat: null, lng: null);
    }
  }

  Future<void> _onRegisterPressed() async {
    if (_submitting) return;

    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final phone = _phoneCtl.text.trim();
    final addressText = _addressCtl.text.trim();
    final password = _passwordCtl.text;
    final gpsRaw = _gpsCtl.text.trim();

    if ([name, email, phone, password, gpsRaw].any((v) => v.isEmpty)) {
      _showSnack('กรอกข้อมูลให้ครบทุกช่อง');
      return;
    }
    if (!email.contains('@')) {
      _showSnack('อีเมลไม่ถูกต้อง');
      return;
    }
    if (password.length < 6) {
      _showSnack('รหัสผ่านต้องอย่างน้อย 6 ตัวอักษร');
      return;
    }

    setState(() => _submitting = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final url = await _uploadProfile(uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'user_id': uid,
          'name': name,
          'user_email': email,
          'phone_number': phone,
          'profile_image': url,
          'password': password,
          'auth_uid': uid,
        });

        final gps = _parseGps(gpsRaw);
        if (gps.lat != null && gps.lng != null && gps.place != null) {
          // เก็บลง collection addresses พร้อม user_id
          await FirebaseFirestore.instance.collection('addresses').add({
            'owner_user_id': uid,
            'address_text': gps.place,
            'gps': {'lat': gps.lat, 'lng': gps.lng},
          });

          // เก็บใน users.addresses แค่ชื่อสถานที่
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'addresses': FieldValue.arrayUnion([
              {'address_text': gps.place},
            ]),
          });
        }
      });

      if (!mounted) return;
      _showSnack('สมัครสมาชิกสำเร็จ', ok: true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'อีเมลนี้ถูกใช้แล้ว',
        'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
        'weak-password' => 'รหัสผ่านไม่ปลอดภัย (อย่างน้อย 6 ตัวอักษร)',
        _ => 'สมัครไม่สำเร็จ: ${e.message ?? e.code}',
      };
      _showSnack(msg);
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // -------------------- เลือก GPS จาก Map --------------------
  Future<void> _selectGpsFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map) {
      final pickedLocation = result['location'];
      final pickedAddress = result['address'];

      if (pickedLocation != null) {
        setState(() {
          // แสดงชื่อสถานที่พร้อมพิกัดใน TextField GPS
          if (pickedAddress != null && pickedAddress is String) {
            _gpsCtl.text =
                '$pickedAddress (${pickedLocation.latitude}, ${pickedLocation.longitude})';
            _addressCtl.text =
                pickedAddress; // เก็บชื่อที่อยู่ไว้บันทึก Firestore
          } else {
            // ถ้าไม่มีชื่อสถานที่ แสดงแค่พิกัด
            _gpsCtl.text =
                '${pickedLocation.latitude}, ${pickedLocation.longitude}';
          }
        });
      }
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 120,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFEE600),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'สมัครสมาชิก',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5B5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text(
                          'ผู้ใช้ระบบ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterRider(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Colors.white),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text(
                          'ไรเดอร์',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            // รูปโปรไฟล์
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(60.0),
                        child: _imageBytes != null
                            ? Image.memory(
                                _imageBytes!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildTextField(
              hintText: 'ชื่อ-สกุล',
              icon: Icons.person_outline,
              controller: _nameCtl,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              hintText: 'อีเมล',
              icon: Icons.mail_outline,
              controller: _emailCtl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              hintText: 'หมายเลขโทรศัพท์',
              icon: Icons.phone_outlined,
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              hintText: 'Password',
              icon: Icons.lock_outline,
              controller: _passwordCtl,
            ),
            const SizedBox(height: 16),
            // ช่อง GPS แทนที่อยู่
            _buildTextField(
              hintText: 'พิกัด GPS ของสถานที่รับสินค้า',
              icon: Icons.gps_fixed_outlined,
              controller: _gpsCtl,
              isGpsField: true,
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- widgets --------------------
  Widget _buildTextField({
    required String hintText,
    IconData? icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool isGpsField = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isGpsField,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onTap: isGpsField ? _selectGpsFromMap : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF5B5B5B)),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF5B5B5B))
            : null,
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 16.0,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hintText,
    IconData? icon,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF5B5B5B)),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF5B5B5B))
            : null,
        suffixIcon: const Icon(
          Icons.remove_red_eye_outlined,
          color: Color(0xFF5B5B5B),
        ),
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 16.0,
        ),
      ),
    );
  }
}
