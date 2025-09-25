import 'package:delivery/rider/HomePageRider.dart';
import 'package:delivery/rider/registerRider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  int selectedRole = 1; // keep for compatibility
  bool obscure = true;

  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();

  bool _loading = false;

  // theme
  static const kYellow = Color(0xFFF0DB0C);
  static const kTextBlack = Color(0xFF111111);
  static const kBlue = Color(0xFF2F47FF);

  @override
  void dispose() {
    emailCtl.dispose();
    passCtl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : Colors.red),
    );
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'อีเมลไม่ถูกต้อง';
      case 'user-not-found':
      case 'wrong-password':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกปิดการใช้งาน';
      default:
        return 'เข้าสู่ระบบไม่สำเร็จ: ${e.message ?? e.code}';
    }
  }

  /// ล็อกอินได้ทั้ง user และ rider โดยตรวจสอบคอลเลกชันจาก uid
  Future<void> _loginRider() async {
    if (_loading) return;

    final email = emailCtl.text.trim().toLowerCase();
    final pass  = passCtl.text;

    if (email.isEmpty || pass.isEmpty) {
      _showSnack('กรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      final uid = cred.user!.uid;

      final fs = FirebaseFirestore.instance;

      // 1) เช็คว่าเป็น Rider ไหม
      final riderDoc = await fs.collection('riders').doc(uid).get();
      if (riderDoc.exists) {
        final name = (riderDoc.data()?['name'] as String?)?.trim();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePageRider(
              name: (name != null && name.isNotEmpty) ? name : email,
            ),
          ),
        );
        return;
      }

      // 2) ถ้าไม่ใช่ Rider → เช็คเป็นผู้ใช้ระบบ
      final userDoc = await fs.collection('users').doc(uid).get();
      if (userDoc.exists) {
        // ถ้าคุณมีหน้าโฮมของ user เช่น HomeUser ให้เปลี่ยนปลายทางตรงนี้
        if (!mounted) return;
        return;
      }

      // 3) ไม่พบทั้งสองบทบาท
      await FirebaseAuth.instance.signOut();
      _showSnack('บัญชียังไม่ได้ลงทะเบียนเป็นผู้ใช้ระบบหรือไรเดอร์');
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapAuthError(e));
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailCtl.text.trim().toLowerCase();
    if (email.isEmpty) {
      _showSnack('กรอกอีเมลก่อน');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack('ส่งอีเมลสำหรับรีเซ็ตรหัสผ่านแล้ว', ok: true);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'ส่งอีเมลไม่สำเร็จ');
    }
  }

  // -------------------- UI ตามภาพ (ไม่แก้โครง/สไตล์) --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header
          Container(
            height: 160,
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 24),
            decoration: const BoxDecoration(
              color: kYellow,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            alignment: Alignment.bottomCenter,
            child: const Text(
              'เข้าสู่ระบบ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: kTextBlack,
              ),
            ),
          ),

          // content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _inputBox(
                        controller: emailCtl,
                        hint: 'Email',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 18),
                      _inputBox(
                        controller: passCtl,
                        hint: 'Password',
                        icon: Icons.lock_rounded,
                        obscure: obscure, // toggle
                        suffix: InkWell(
                          onTap: () => setState(() => obscure = !obscure),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 22,
                              color: Colors.black.withOpacity(.75),
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFE1C700),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          child: const Text('ลืมรหัสผ่าน?'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 190,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _loginRider, // กันกดซ้ำ
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kYellow,
                              foregroundColor: kTextBlack,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('เข้าสู่ระบบ'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterRider()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: kBlue,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          child: const Text('สมัครสมาชิก'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // input box (UI เดิม)
  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black.withOpacity(.5)),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(.45),
          fontSize: 14.5,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        filled: false,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kYellow, width: 1.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kYellow, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 14.5, color: kTextBlack),
    );
  }
}
