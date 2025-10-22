import 'dart:convert';
import 'dart:typed_data';
import 'package:delivery/map/map_register.dart';
import 'package:delivery/rider/registerRider.dart';
import 'package:delivery/user/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

// ***** 1. เพิ่ม Config สำหรับ Cloudinary *****
class CloudinaryConfig {
  static const String cloudName = 'dwltvhlju';
  static const String uploadPreset = 'delivery';
}
// ******************************************

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
  final _addressCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _gpsCtl = TextEditingController();

  // image state
  final _picker = ImagePicker();
  Uint8List? _imageBytes; // สำหรับแสดงผล preview
// แก้ไข: เพิ่มตัวแปรสำหรับเก็บ File

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  String _hashPasswordOnly(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  Future<void> _pickImage() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (xFile == null) return;

      final fileExtension = xFile.path.split('.').last.toLowerCase();
      if (fileExtension != 'jpg' &&
          fileExtension != 'jpeg' &&
          fileExtension != 'png') {
        _showSnack('ไม่รองรับไฟล์ประเภทนี้ (รองรับเฉพาะ jpg, jpeg, png)');
        return;
      }

      // แก้ไข: เก็บ File ไว้เพื่ออัปโหลด

      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
      });
    } catch (e) {
      _showSnack('เลือกรูปไม่สำเร็จ: $e');
    }
  }

  Future<String?> _uploadProfileToCloudinary(Uint8List imageBytes) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        return decodedData['secure_url'];
      } else {
        _showSnack('อัปโหลดไป Cloudinary ไม่สำเร็จ: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาดในการเชื่อมต่อ Cloudinary: $e');
      return null;
    }
  }

  // --- ฟังก์ชันนี้ถูกต้องแล้ว ---
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
      final firestore = FirebaseFirestore.instance;

      final phoneCheck = await firestore
          .collection('users')
          .where('phone_number', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        _showSnack('เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว');
        if (mounted) setState(() => _submitting = false);
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      String? url;
      if (_imageBytes != null) {
        url = await _uploadProfileToCloudinary(_imageBytes!);
      }

      final passwordHash = _hashPasswordOnly(password);

      // VVVVVVVVVVVVVVVVVV โค้ดส่วนที่แก้ไข VVVVVVVVVVVVVVVVVV
      await firestore.runTransaction((transaction) async {
        final userRef = firestore.collection('users').doc(uid);
        final gps = _parseGps(gpsRaw);

        // เตรียมข้อมูลที่อยู่ไว้ล่วงหน้า
        List<Map<String, dynamic>> initialAddresses = [];
        if (gps.lat != null && gps.lng != null && gps.place != null) {
          initialAddresses.add({
            'address_text': gps.place,
            'gps': {'lat': gps.lat, 'lng': gps.lng},
          });
        }

        // สร้างเอกสารผู้ใช้พร้อมที่อยู่ "ในขั้นตอนเดียว"
        transaction.set(userRef, {
          'user_id': uid,
          'name': name,
          'user_email': email,
          'phone_number': phone,
          'profile_image': url,
          'auth_uid': uid,
          'password_hash': passwordHash,
          'created_at': FieldValue.serverTimestamp(),
          'addresses': initialAddresses, // <-- ใส่ที่อยู่ตรงนี้เลย ไม่ต้อง update
        });
      });
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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
        'weak-password' => 'รหัสผ่านไม่ปลอดภัย',
        _ => 'สมัครไม่สำเร็จ: ${e.message ?? e.code}',
      };
      _showSnack(msg);
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
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
          if (pickedAddress != null && pickedAddress is String) {
            _gpsCtl.text =
                '$pickedAddress (${pickedLocation.latitude}, ${pickedLocation.longitude})';
            _addressCtl.text = pickedAddress;
          } else {
            _gpsCtl.text =
                '${pickedLocation.latitude}, ${pickedLocation.longitude}';
          }
        });
      }
    }
  }

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
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
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
      onTap: isGpsField ? () => _selectGpsFromMap() : null,
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
      controller: controller ?? _passwordCtl,
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
