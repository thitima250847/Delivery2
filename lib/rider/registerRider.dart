import 'dart:typed_data';
import 'package:delivery/user/registerUser.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  Uint8List? _imageBytes; // preview
  String? _uploadedImageUrl; // storage url

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

  // //คำสั่งที่ใช้สำหรับเลือกไฟล์รูปภาพจากเครื่อง

  Future<void> _pickImage() async {
    try {
      print('กำลังจะเปิดหน้าจอเลือกรูปภาพ...');
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      // ตรวจสอบว่าผู้ใช้ได้เลือกรูปภาพหรือไม่
      if (x == null) {
        print('ผู้ใช้ยกเลิกการเลือกรูปภาพ.');
        return;
      }

      print('เลือกรูปภาพสำเร็จ: ${x.name}');

      final bytes = await x.readAsBytes();
      if (!mounted) return;

      // ตรวจสอบว่าได้ข้อมูลรูปภาพมาหรือไม่
      if (bytes.isNotEmpty) {
        print('แปลงรูปภาพเป็น bytes สำเร็จ! ขนาด: ${bytes.length} bytes');
      } else {
        print('แปลงรูปภาพเป็น bytes ไม่สำเร็จ.');
      }

      setState(() {
        _imageBytes = bytes;
      });
    } catch (e) {
      print('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
      _showSnack('เลือกรูปไม่สำเร็จ: $e');
    }
  }

  // ----- upload to Storage: rider_vehicles/<uid>.jpg -----
  Future<String?> _uploadVehicleImage(String uid) async {
    if (_imageBytes == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref('rider_vehicles/$uid.jpg');
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

  // ----- register rider (Auth + Firestore:riders/{uid}) -----
  Future<void> _onRegisterPressed() async {
    if (_submitting) return;

    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final phone = _phoneCtl.text.trim();
    final plate = _plateCtl.text.trim();
    final password = _passwordCtl.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        plate.isEmpty ||
        password.isEmpty) {
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
      // 1) สร้างผู้ใช้
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // 2) อัปโหลดรูป (ถ้ามี)
      final url = await _uploadVehicleImage(uid);
      _uploadedImageUrl = url;

      // 3) เขียนโปรไฟล์ไรเดอร์
      await FirebaseFirestore.instance.collection('riders').doc(uid).set({
        'user_id': uid,
        'name': name,
        'rider_email': email, // << เปลี่ยนตาม ER
        'phone_number': phone,
        'license_plate': plate,
        'vehicle_image': url, // << เปลี่ยนตาม ER
        'is_available': false,
        'current_latitude': null,
        'current_longitude': null,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showSnack('สมัครสมาชิกสำเร็จ', success: true);
      Navigator.pop(context);
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

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // ========================= UI เดิม =========================
  static const kYellow = RegisterRider.kYellow;
  static const kGrey = RegisterRider.kGrey;

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
            color: kYellow,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'สมัครสมาชิก',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:  () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterUser(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text(
                          'ผู้ใช้ระบบ',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
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
                        child: const Text(
                          'ไรเดอร์',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
            // avatar (เพิ่มเลือก/preview รูป แต่ UI เดิม)
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _pickImage, // ย้าย GestureDetector มาคลุมทั้ง Stack
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
                      // ส่วนของไอคอน add ยังคงอยู่
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
            _buildTextField(
              hintText: 'ทะเบียนรถ',
              icon: Icons.directions_car_outlined,
              controller: _plateCtl,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              hintText: 'Password',
              icon: Icons.lock_outline,
              controller: _passwordCtl,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                ),
                child: Text(
                  _submitting ? 'กำลังสมัคร...' : 'สมัครสมาชิก',
                  style: const TextStyle(
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

  // ---- widgets เดิม ----
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
        prefixIcon: icon != null
            ? Icon(icon, color: RegisterRider.kGrey)
            : null,
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: RegisterRider.kYellow,
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: RegisterRider.kYellow,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: RegisterRider.kYellow,
            width: 2.0,
          ),
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
        hintStyle: const TextStyle(color: RegisterRider.kGrey),
        prefixIcon: icon != null
            ? Icon(icon, color: RegisterRider.kGrey)
            : null,
        suffixIcon: const Icon(
          Icons.remove_red_eye_outlined,
          color: RegisterRider.kGrey,
        ),
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: RegisterRider.kYellow,
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: RegisterRider.kYellow,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: RegisterRider.kYellow,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 16.0,
        ),
      ),
    );
  }
}
