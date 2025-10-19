import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:delivery/user/login.dart';
import 'package:delivery/user/registerUser.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

// ***** 1. เพิ่ม Config สำหรับ Cloudinary *****
class CloudinaryConfig {
  static const String cloudName = 'dwltvhlju'; // <-- ใส่ Cloud Name ของคุณ
  static const String uploadPreset = 'delivery'; // <-- ใส่ Upload Preset ของคุณ
}
// ******************************************


class RegisterRider extends StatefulWidget {
  const RegisterRider({super.key});

  static const kYellow = Color(0xFFFEE600);
  static const kGrey = Color(0xFF5B5B5B);

  @override
  State<RegisterRider> createState() => _RegisterRiderState();
}

class _RegisterRiderState extends State<RegisterRider> {
  // controllers
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _plateCtl = TextEditingController();
  final _passwordCtl = TextEditingController();

  // image state
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageExtension;

  bool _submitting = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _plateCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  // Helpers สำหรับ Hash รหัสผ่าน (เหมือนเดิม)
  Uint8List _generateSalt([int length = 16]) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => r.nextInt(256)));
  }

  String _hashPassword(String password, Uint8List salt, {int iterations = 10000}) {
    var mac = Hmac(sha256, salt);
    var bytes = mac.convert(utf8.encode(password)).bytes;
    for (var i = 1; i < iterations; i++) {
      mac = Hmac(sha256, salt);
      bytes = mac.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  // เลือกรูป (เหมือนเดิม)
  Future<void> _pickImage() async {
    try {
      final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (xFile == null) return;

      final fileExtension = xFile.path.split('.').last.toLowerCase();
      if (fileExtension != 'jpg' && fileExtension != 'jpeg' && fileExtension != 'png') {
        _showSnack('ไม่รองรับไฟล์ประเภทนี้ (รองรับเฉพาะ jpg, jpeg, png)');
        return;
      }

      final bytes = await xFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageExtension = fileExtension;
      });
    } catch (e) {
      _showSnack('เลือกรูปไม่สำเร็จ: $e');
    }
  }

  // ***** 2. เพิ่มฟังก์ชันสำหรับอัปโหลดไป Cloudinary *****
  Future<String?> _uploadProfileToCloudinary(Uint8List imageBytes) async {
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');
    
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'upload.jpg'));

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
  // *******************************************************

  // สมัครสมาชิก + เขียน Firestore
  Future<void> _onRegisterPressed() async {
    if (_submitting) return;

    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final phone = _phoneCtl.text.trim();
    final plate = _plateCtl.text.trim();
    final password = _passwordCtl.text;

    if ([name, email, phone, plate, password].any((v) => v.isEmpty)) {
      _showSnack('กรอกข้อมูลให้ครบทุกช่อง');
      return;
    }
    if (_imageBytes == null) {
      _showSnack('กรุณาเลือกรูปโปรไฟล์');
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
      // 1) สร้างผู้ใช้ใน Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // ***** 3. เปลี่ยนมาเรียกใช้อัปโหลดไป Cloudinary *****
      String? url;
      if (_imageBytes != null) {
        url = await _uploadProfileToCloudinary(_imageBytes!);
      }
      // **************************************************

      // 3) สร้าง salt + hash (เหมือนเดิม)
      final salt = _generateSalt(16);
      final passwordHash = _hashPassword(password, salt, iterations: 10000);

      // 4) บันทึกข้อมูล rider (ใช้ url จาก Cloudinary)
      await FirebaseFirestore.instance.collection('riders').doc(uid).set({
        'user_id': uid,
        'auth_uid': uid,
        'name': name,
        'rider_email': email,
        'phone_number': phone,
        'license_plate': plate,
        'vehicle_image': url, // <-- url จาก Cloudinary จะถูกบันทึกที่นี่
        'is_available': false,
        'current_latitude': null,
        'current_longitude': null,
        'password_hash': passwordHash,
        // เพิ่ม salt เข้าไปใน Firestore เพื่อใช้ตรวจสอบรหัสผ่านในอนาคต
        'password_salt': base64Encode(salt), 
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showSnack('สมัครสมาชิกสำเร็จ', success: true);

      // กลับหน้า Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
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

  @override
  Widget build(BuildContext context) {
    // UI ทั้งหมดเหมือนเดิม ไม่ต้องแก้ไข
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 120,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: RegisterRider.kYellow,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text('สมัครสมาชิก',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterUser()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('ผู้ใช้ระบบ', style: TextStyle(color: Colors.black, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B5B5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Colors.white),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('ไรเดอร์', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                        ? Image.memory(_imageBytes!, width: 120, height: 120, fit: BoxFit.cover)
                        : Container(
                            width: 120, height: 120, color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 60, color: Colors.white),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(hintText: 'ชื่อ-สกุล', icon: Icons.person_outline, controller: _nameCtl, textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            _buildTextField(hintText: 'อีเมล', icon: Icons.mail_outline, controller: _emailCtl, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            _buildTextField(hintText: 'หมายเลขโทรศัพท์', icon: Icons.phone_outlined, controller: _phoneCtl, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            _buildTextField(hintText: 'ทะเบียนรถ', icon: Icons.directions_car_outlined, controller: _plateCtl, textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            _buildPasswordField(hintText: 'Password', icon: Icons.lock_outline, controller: _passwordCtl),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RegisterRider.kYellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black))
                    : const Text('สมัครสมาชิก', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ย่อย (UI เดิม) ---
  Widget _buildTextField({
    required String hintText,
    IconData? icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: RegisterRider.kGrey),
        prefixIcon: icon != null ? Icon(icon, color: RegisterRider.kGrey) : null,
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: RegisterRider.kYellow, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: RegisterRider.kYellow, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: RegisterRider.kYellow, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
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
        hintStyle: const TextStyle(color: RegisterRider.kGrey),
        prefixIcon: icon != null ? Icon(icon, color: RegisterRider.kGrey) : null,
        suffixIcon: const Icon(Icons.remove_red_eye_outlined, color: RegisterRider.kGrey),
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: RegisterRider.kYellow, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: RegisterRider.kYellow, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: RegisterRider.kYellow, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      ),
    );
  }
}