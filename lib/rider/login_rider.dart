// import 'package:delivery/rider/HomePageRider.dart';
// import 'package:delivery/rider/registerRider.dart';
// import 'package:delivery/user/login_user.dart';
// import 'package:flutter/material.dart';

// // เพิ่ม import backend
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class LoginRiderScreen extends StatefulWidget {
//   const LoginRiderScreen({super.key});

//   @override
//   State<LoginRiderScreen> createState() => _LoginRiderScreenState();
// }

// class _LoginRiderScreenState extends State<LoginRiderScreen> {
//   int selectedRole = 1; // เริ่มเป็นไรเดอร์
//   bool obscure = true;

//   final emailCtl = TextEditingController();
//   final passCtl = TextEditingController();

//   bool _loading = false; // ไม่เปลี่ยน UI แค่กันกดรัว ๆ

//   static const kYellow = Color(0xFFF0DB0C);
//   static const kDarkCard = Color(0xFF4D4D4D);
//   static const kTextBlack = Color(0xFF111111);
//   static const kBlue = Color(0xFF2F47FF);

//   @override
//   void dispose() {
//     emailCtl.dispose();
//     passCtl.dispose();
//     super.dispose();
//   }

//   // -------------------- BACKEND LOGIC --------------------

//   void _showSnack(String msg, {bool ok = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : Colors.red),
//     );
//   }

//   Future<void> _loginRider() async {
//     if (_loading) return;
//     final email = emailCtl.text.trim();
//     final pass = passCtl.text;

//     if (email.isEmpty || pass.isEmpty) {
//       _showSnack('กรอกอีเมลและรหัสผ่าน');
//       return;
//     }

//     setState(() => _loading = true);
//     try {
//       // 1) Login ด้วย Firebase Auth
//       final cred = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: pass);
//       final uid = cred.user!.uid;

//       // 2) ตรวจว่าเป็น Rider จริง (ต้องมี riders/{uid})
//       final snap = await FirebaseFirestore.instance
//           .collection('riders')
//           .doc(uid)
//           .get();

//       if (!snap.exists) {
//         await FirebaseAuth.instance.signOut();
//         _showSnack('บัญชีนี้ไม่ใช่ Rider หรือยังไม่ได้สมัคร Rider');
//         return;
//       }

//       final data = snap.data() ?? {};
//       final name = (data['name'] as String?)?.trim();
//       if (!mounted) return;

//       // ไปหน้า HomePageRider (เหมือนเดิม)
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => HomePageRider(
//             name: (name != null && name.isNotEmpty) ? name : email,
//           ),
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       final msg = switch (e.code) {
//         'invalid-email' => 'อีเมลไม่ถูกต้อง',
//         'user-not-found' || 'wrong-password' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
//         'user-disabled' => 'บัญชีนี้ถูกปิดการใช้งาน',
//         _ => 'เข้าสู่ระบบไม่สำเร็จ: ${e.message ?? e.code}',
//       };
//       _showSnack(msg);
//     } catch (e) {
//       _showSnack('เกิดข้อผิดพลาด: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _forgotPassword() async {
//     final email = emailCtl.text.trim();
//     if (email.isEmpty) {
//       _showSnack('กรอกอีเมลก่อน');
//       return;
//     }
//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       _showSnack('ส่งอีเมลสำหรับรีเซ็ตรหัสผ่านแล้ว', ok: true);
//     } on FirebaseAuthException catch (e) {
//       _showSnack(e.message ?? 'ส่งอีเมลไม่สำเร็จ');
//     }
//   }

//   // -------------------- UI เดิม (ไม่เปลี่ยนโครง) --------------------

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // หัวเหลือง
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 36, 16, 24),
//             decoration: const BoxDecoration(
//               color: kYellow,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(26),
//                 bottomRight: Radius.circular(26),
//               ),
//             ),
//             child: Column(
//               children: [
//                 const Text(
//                   'เข้าสู่ระบบ',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.w900,
//                     color: kTextBlack,
//                   ),
//                 ),
//                 const SizedBox(height: 18),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // ผู้ใช้ระบบ ->ไปหน้า LoginUserScreen
//                     _rolePill(
//                       label: 'ผู้ใช้ระบบ',
//                       bg: Colors.white,
//                       fg: kTextBlack,
//                       onTap: () {
//                         setState(() => selectedRole = 0);
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const LoginUserScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(width: 14),
//                     // ไรเดอร์ (หน้าเดิม)
//                     _rolePill(
//                       label: 'ไรเดอร์',
//                       bg: kDarkCard,
//                       fg: kYellow,
//                       onTap: () => setState(() => selectedRole = 1),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // ฟอร์ม (กึ่งกลาง)
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(vertical: 28),
//               child: Align(
//                 alignment: Alignment.topCenter,
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 320),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       _inputBox(
//                         controller: emailCtl,
//                         hint: 'Email',
//                         icon: Icons.person_rounded,
//                       ),
//                       const SizedBox(height: 18),
//                       _inputBox(
//                         controller: passCtl,
//                         hint: 'Password',
//                         icon: Icons.lock_rounded,
//                         obscure: obscure,
//                         suffix: InkWell(
//                           onTap: () => setState(() => obscure = !obscure),
//                           child: Padding(
//                             padding: const EdgeInsets.only(right: 10),
//                             child: Icon(
//                               obscure
//                                   ? Icons.visibility_outlined
//                                   : Icons.visibility_off_outlined,
//                               size: 22,
//                               color: Colors.black.withOpacity(.75),
//                             ),
//                           ),
//                         ),
//                       ),

//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: TextButton(
//                           onPressed: _forgotPassword, // เชื่อม backend
//                           style: TextButton.styleFrom(
//                             foregroundColor: const Color(0xFFE1C700),
//                             padding: EdgeInsets.zero,
//                             textStyle: const TextStyle(
//                               fontSize: 12.5,
//                               fontWeight: FontWeight.w600,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                           child: const Text('ลืมรหัสผ่าน?'),
//                         ),
//                       ),

//                       const SizedBox(height: 14),

//                       // เข้าสู่ระบบ -> HomePageRider
//                       Align(
//                         alignment: Alignment.center,
//                         child: SizedBox(
//                           width: 190,
//                           height: 46,
//                           child: ElevatedButton(
//                             onPressed: _loginRider, // เชื่อม backend
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: kYellow,
//                               foregroundColor: kTextBlack,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               textStyle: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w900,
//                               ),
//                             ),
//                             child: const Text('เข้าสู่ระบบ'),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 14),

//                       // สมัครสมาชิก -> RegisterRider
//                       Align(
//                         alignment: Alignment.center,
//                         child: TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => const RegisterRider(),
//                               ),
//                             );
//                           },
//                           style: TextButton.styleFrom(
//                             foregroundColor: kBlue,
//                             textStyle: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                           child: const Text('สมัครสมาชิก'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _rolePill({
//     required String label,
//     required Color bg,
//     required Color fg,
//     required VoidCallback onTap,
//   }) {
//     return SizedBox(
//       height: 44,
//       child: Material(
//         color: bg,
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 22),
//             alignment: Alignment.center,
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: fg,
//                 fontWeight: FontWeight.w900,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _inputBox({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     Widget? suffix,
//     bool obscure = false,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscure,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: Colors.black.withOpacity(.7)),
//         suffixIcon: suffix,
//         hintText: hint,
//         hintStyle: TextStyle(
//           color: Colors.black.withOpacity(.55),
//           fontSize: 14.5,
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: kYellow, width: 1.4),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: kYellow, width: 1.8),
//         ),
//       ),
//       style: const TextStyle(fontSize: 14.5, color: kTextBlack),
//     );
//   }
// }
