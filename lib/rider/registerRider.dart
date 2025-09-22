import 'package:flutter/material.dart';

class RegisterRider extends StatelessWidget {
  const RegisterRider({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.transparent, // ทำให้ AppBar โปร่งใส
        elevation: 0, // ลบเงาของ AppBar
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFEE600),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30), // ปรับมุมโค้งมนที่ขอบซ้าย
              bottomRight: Radius.circular(30), // ปรับมุมโค้งมนที่ขอบขวา
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'สมัครสมาชิก',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),
              // User/Rider Toggle Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text(
                          'ผู้ใช้ระบบ',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 16,
                          ),
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
                            side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text(
                          'ไรเดอร์',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 16,
                          ),
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
            // Profile Picture Section
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60.0), // Rounded corners for the image
                  child: Image.network(
                    'https://static.wixstatic.com/media/c6a3da_db59e90fb0a84dd2ba396718cf717077~mv2.webp/v1/fill/w_740,h_444,al_c,q_80,usm_0.66_1.00_0.01,enc_avif,quality_auto/c6a3da_db59e90fb0a84dd2ba396718cf717077~mv2.webp', // URL from the internet
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFFD9D9D9),
                        child: Icon(Icons.person, size: 60, color: Color(0xFF5B5B5B)),
                      );
                    },
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
            const SizedBox(height: 30),

            // Form Fields
            _buildTextField(
                hintText: 'ชื่อ-สกุล', icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(
                hintText: 'อีเมล', icon: Icons.mail_outline), // Corrected icon for email
            const SizedBox(height: 16),
            _buildTextField(
                hintText: 'หมายเลขโทรศัพท์', icon: Icons.phone_outlined), // Added phone icon
            const SizedBox(height: 16),
            _buildTextField(
                hintText: 'ทะเบียนรถ', icon: Icons.directions_car_outlined), // Added car icon for registration
            const SizedBox(height: 16),
            _buildPasswordField(
                hintText: 'Password', icon: Icons.lock_outline),
            const SizedBox(height: 16),


            // Register Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                ),
                child: const Text(
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

  Widget _buildTextField({required String hintText, IconData? icon}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF5B5B5B)),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5B5B5B)) : null,
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0), // Added yellow border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0), // Added yellow border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0), // Added yellow border
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      ),
    );
  }

  Widget _buildPasswordField({required String hintText, IconData? icon}) {
    return TextFormField(
      obscureText: true,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF5B5B5B)),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF5B5B5B)) : null,
        suffixIcon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF5B5B5B)),
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0), // Added yellow border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0), // Added yellow border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFEE600), width: 2.0), // Added yellow border
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      ),
    );
  }
}
