import 'package:flutter/material.dart';
import 'login_rider.dart'; 

class HomePageRider extends StatelessWidget {
  const HomePageRider({super.key, this.name = 'Tester'});
  final String name;

  // โทนสีให้ตรงชุด login
  static const kYellow = Color(0xFFF0DB0C);
  static const kTextBlack = Color(0xFF111111);
  static const kGreyIcon = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---- เนื้อหา ----
      body: Column(
        children: [
          // หัวสีเหลือง โค้งมุมล่าง
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
            decoration: const BoxDecoration(
              color: kYellow,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ข้อความ “สวัสดี / Tester”
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สวัสดี',
                        style: TextStyle(
                          color: kTextBlack,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          color: kTextBlack,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // วงกลมโปรไฟล์สีเทาพร้อมไอคอน
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreyIcon,
                  ),
                  child: const Icon(Icons.person, size: 32, color: Colors.white),
                ),
              ],
            ),
          ),

          // การ์ด “รายการสินค้าที่ต้องไปส่ง”
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Material(
                color: Colors.white,
                elevation: 3,
                shadowColor: Colors.black.withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: const Text(
                    'รายการสินค้าที่ต้องไปส่ง',
                    style: TextStyle(
                      color: kYellow,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // เว้นพื้นที่เนื้อหา (อนาคตใส่ลิสต์งานได้)
          const Expanded(child: SizedBox()),
        ],
      ),

      // ---- แถบล่าง ----
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BottomItem(
                icon: Icons.home_rounded,
                label: 'หน้าแรก',
                color: Colors.black, // ตามภาพ: ไอคอนสีดำ
                onTap: () {}, // ปัจจุบันอยู่หน้า Home แล้ว
              ),
              _BottomItem(
                icon: Icons.logout_rounded,
                label: 'ออกจากระบบ',
                color: kYellow, // ตามภาพ: ไอคอนและตัวอักษรเหลือง
                onTap: () {
                  // ✅ ออกจากระบบ -> กลับไปหน้า Login และล้างเส้นทางเก่า
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginRiderScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ไอเท็มแถบล่าง
class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
