import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/senditem.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rider Home UI',
      theme: ThemeData(fontFamily: 'Prompt'),
      debugShowCheckedModeBanner: false,
      home: const SearchRecipientScreen(),
    );
  }
}

class SearchRecipientScreen extends StatelessWidget {
  const SearchRecipientScreen({Key? key}) : super(key: key);

  static const Color primaryYellow = Color(0xFFFDE100);

  @override
  Widget build(BuildContext context) {
    // <--- context ตัวนี้
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        toolbarHeight: 90.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryPage()),
            );
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
            icon: Icon(Icons.account_circle, color: Colors.grey[600], size: 50),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. ช่องค้นหา (เหมือนเดิม)
            TextField(
              controller: TextEditingController(text: "0967490007"),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                hintText: "กรอกเบอร์โทรหรือชื่อ",
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

            // 2. ปุ่มค้นหา (เหมือนเดิม)
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
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
            const SizedBox(height: 24.0),

            // 3. รายการผลลัพธ์
            Expanded(
              child: ListView(
                children: [
                  // vvvv 2. ส่ง context เข้าไป vvvv
                  _buildContactTile(
                    context, // <--- ส่ง context
                    imageUrl: "https://i.imgur.com/v8SjA9H.png",
                    name: "ฟิวพี",
                    phone: "0967490007",
                  ),
                  _buildContactTile(
                    context, // <--- ส่ง context
                    imageUrl: "https://i.imgur.com/v8SjA9H.png",
                    name: "Soduku kiki",
                    phone: "096*******",
                  ),
                  _buildContactTile(
                    context, // <--- ส่ง context
                    imageUrl: "https://i.imgur.com/v8SjA9H.png",
                    name: "Soduku kiki",
                    phone: "09674****7",
                  ),
                  _buildContactTile(
                    context, // <--- ส่ง context
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
  Widget _buildContactTile(
    BuildContext context, { // <--- 1. รับ context เข้ามา
    required String imageUrl,
    required String name,
    required String phone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(imageUrl),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          phone,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: ElevatedButton(
          // vvvv 3. เพิ่ม Navigator.push ที่นี่ vvvv
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SendItemPage()),
            );

            print('เลือก: $name'); // (เอาไว้ทดสอบ)
          },
          // ^^^^ ^^^^
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
