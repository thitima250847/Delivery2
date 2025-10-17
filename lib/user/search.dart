import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Search UI Demo',
      theme: ThemeData(
        // ตั้งค่า font เริ่มต้นให้เข้ากับ UI
        fontFamily: 'Prompt', // (หากคุณมี font นี้ในโปรเจกต์)
      ),
      debugShowCheckedModeBanner: false,
      home: const SearchRecipientScreen(),
    );
  }
}

class SearchRecipientScreen extends StatelessWidget {
  const SearchRecipientScreen({Key? key}) : super(key: key);

  // กำหนดสีเหลืองหลักที่ใช้ในแอป
  static const Color primaryYellow = Color(0xFFFDE100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0, // ไม่มีเงาใต้ AppBar
        // vvvv เพิ่มบรรทัดนี้เพื่อปรับความสูง vvvv
        toolbarHeight: 90.0, // (ค่าปกติคือ 56.0)
        // ^^^^ สามารถปรับตัวเลขนี้ได้ตามต้องการ ^^^^
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // ใส่โค้ดสำหรับการย้อนกลับที่นี่
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "ค้นหาผู้รับ",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: Colors.grey[600], // สีไอคอนโปรไฟล์
              size: 50,
            ),
            onPressed: () {
              // ใส่โค้ดสำหรับเปิดหน้าโปรไฟล์
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. ช่องค้นหา
            TextField(
              controller: TextEditingController(text: "0967490007"),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                hintText: "กรอกเบอร์โทรหรือชื่อ",
                // ตั้งค่าเส้นขอบ
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(
                    color: primaryYellow,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // 2. ปุ่มค้นหา
            Center(
              // <-- vvv 1. ใช้ Center ครอบเพื่อจัดกลาง
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  // vvv 2. เพิ่ม padding แนวนอน (horizontal) ให้ปุ่มกว้างขึ้นตามแบบ
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 80,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  "ค้นหา",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0), // เว้นวรรคก่อนเริ่มลิสต์
            // 3. รายการผลลัพธ์
            Expanded(
              child: ListView(
                children: [
                  // ใช้ฟังก์ชัน helper เพื่อสร้างแต่ละรายการ
                  _buildContactTile(
                    imageUrl:
                        "https://i.imgur.com/v8SjA9H.png", // รูป placeholder
                    name: "ฟิวพี",
                    phone: "0967490007",
                  ),
                  _buildContactTile(
                    imageUrl: "https://i.imgur.com/v8SjA9H.png",
                    name: "Soduku kiki",
                    phone: "096*******",
                  ),
                  _buildContactTile(
                    imageUrl: "https://i.imgur.com/v8SjA9H.png",
                    name: "Soduku kiki",
                    phone: "09674****7",
                  ),
                  _buildContactTile(
                    imageUrl: "https://i.imgur.com/v8SjA9H.png",
                    name: "Soduku kiki",
                    phone: "*****90007",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper Widget สำหรับสร้างแต่ละรายการในลิสต์
  Widget _buildContactTile({
    required String imageUrl,
    required String name,
    required String phone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(imageUrl), // โหลดรูปจาก URL
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          phone,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryYellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: const Text("เลือก", style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
