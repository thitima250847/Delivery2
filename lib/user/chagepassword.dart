import 'package:flutter/material.dart';

// (คุณสามารถลบ main() และ MyApp() ออกได้ หากนำไปรวมกับโปรเจกต์เดิม)
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Change Password UI',
      theme: ThemeData(fontFamily: 'Prompt'),
      debugShowCheckedModeBanner: false,
      home: const ChangePasswordScreen(),
    );
  }
}
// -----------------------------------------------------------------


class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  // กำหนดสีเหลืองหลักที่ใช้ในแอป
  static const Color primaryYellow = Color(0xFFFDE100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        toolbarHeight: 90.0, // (ปรับขนาดตามที่เคยทำ)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "เปลี่ยนรหัสผ่าน",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        // ใช้ SingleChildScrollView เพื่อกันหน้าจอล้น
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // ทำให้ Widget เต็มความกว้าง
            children: [
              
              // 1. ไอคอนโปรไฟล์
              _buildProfileIcon(),
              const SizedBox(height: 32.0),

              // 2. ช่องรหัสผ่าน
              _buildPasswordField(label: "รหัสผ่าน"),
              const SizedBox(height: 16.0),

              // 3. ช่องยืนยันรหัสผ่าน
              _buildPasswordField(label: "ยืนยันรหัสผ่าน"),
              const SizedBox(height: 40.0),

              // 4. ปุ่มบันทึก
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper Widget สำหรับสร้างไอคอนโปรไฟล์
  Widget _buildProfileIcon() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: primaryYellow, width: 4),
        ),
        child: Stack(
          clipBehavior: Clip.none, // อนุญาตให้ไอคอน + ล้นออกมา
          children: [
            Center(
              child: Icon(
                Icons.person,
                color: Colors.grey[700],
                size: 80,
              ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper Widget สำหรับสร้างช่องกรอกรหัสผ่าน
  Widget _buildPasswordField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          obscureText: true, // ทำให้เป็นรหัสผ่าน (ตัวอักษรเป็นจุด)
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: primaryYellow, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper Widget สำหรับสร้างปุ่มบันทึก
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryYellow,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // ปุ่มมน
        ),
        elevation: 0,
      ),
      child: const Text(
        "บันทึก",
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}