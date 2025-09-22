import 'package:flutter/material.dart';

class RegisterRider extends StatelessWidget {
  const RegisterRider({super.key});

  static const kYellow = Color(0xFFFEE600);
  static const kGrey = Color(0xFF5B5B5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
          splashRadius: 22,
        ),
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
              // Toggle ผู้ใช้ระบบ/ไรเดอร์ (ดีไซน์เดิม)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: ถ้ามีหน้า Register ของ "ผู้ใช้ระบบ" ให้ Navigator.pushReplacement ไปหน้านั้น
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
            // รูปโปรไฟล์
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60.0),
                  child: Image.network(
                    'https://static.wixstatic.com/media/c6a3da_db59e90fb0a84dd2ba396718cf717077~mv2.webp/v1/fill/w_740,h_444,al_c,q_80,usm_0.66_1.00_0.01,enc_avif,quality_auto/c6a3da_db59e90fb0a84dd2ba396718cf717077~mv2.webp',
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
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // ฟอร์ม
            _buildTextField(hintText: 'ชื่อ-สกุล', icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(hintText: 'อีเมล', icon: Icons.mail_outline),
            const SizedBox(height: 16),
            _buildTextField(hintText: 'หมายเลขโทรศัพท์', icon: Icons.phone_outlined),
            const SizedBox(height: 16),
            _buildTextField(hintText: 'ทะเบียนรถ', icon: Icons.directions_car_outlined),
            const SizedBox(height: 16),
            _buildPasswordField(hintText: 'Password', icon: Icons.lock_outline),
            const SizedBox(height: 16),

            // ปุ่มสมัครสมาชิก
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: ต่อ backend สมัครสมาชิก
                  Navigator.pop(context); // สมัครเสร็จ -> กลับหน้า LoginRider
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kYellow,
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

  // ---------- Widgets ย่อย ----------

  Widget _buildTextField({required String hintText, IconData? icon}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: kGrey),
        prefixIcon: icon != null ? Icon(icon, color: kGrey) : null,
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: kYellow, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: kYellow, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: kYellow, width: 2.0),
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
        hintStyle: const TextStyle(color: kGrey),
        prefixIcon: icon != null ? Icon(icon, color: kGrey) : null,
        suffixIcon: const Icon(Icons.remove_red_eye_outlined, color: kGrey),
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: kYellow, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: kYellow, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: kYellow, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      ),
    );
  }
}
