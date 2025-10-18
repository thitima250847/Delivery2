import 'package:cloud_functions/cloud_functions.dart';
import 'package:delivery/firebase_options.dart';
import 'package:delivery/user/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp( // เพิ่ม MaterialApp ตรงนี้
      title: 'Delivery App', // ใส่ชื่อแอปของคุณ
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(), // กำหนด RegisterUser เป็นหน้าแรกนย
      debugShowCheckedModeBanner: false, // สามารถลบแบนเนอร์ debug ได้
    );
  }
}
// ตัวอย่างเรียก Cloud Function (ใส่ไว้ตรงปุ่มไหนก็ได้)
Future<void> callGetPackage() async {
  final fns = FirebaseFunctions.instanceFor(region: 'asia-southeast1'); // แก้ให้ตรง region ของคุณ
  final getPackageById = fns.httpsCallable('getPackageById');
  final res = await getPackageById.call({'packageId': 'PACK001'});
  debugPrint('result: ${res.data}');
}
