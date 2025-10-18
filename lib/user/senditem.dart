import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/receive.dart';
import 'package:flutter/material.dart';

// เปลี่ยนเป็น StatefulWidget
class SendItemPage extends StatefulWidget {
  // เพิ่มตัวแปรเพื่อรับข้อมูลผู้รับ
  final Map<String, String> recipientData;

  const SendItemPage({super.key, required this.recipientData});

  @override
  State<SendItemPage> createState() => _SendItemPageState();
}

class _SendItemPageState extends State<SendItemPage> {
  static const Color primaryColor = Color(0xFFFEE146);
  static const Color greenColor = Colors.green;

  // ตัวแปรสำหรับเก็บข้อมูลผู้รับที่ได้รับมา
  String _recipientName = 'ผู้รับ';
  String _recipientPhone = 'ไม่ระบุเบอร์';
  String _recipientAddress = 'ไม่ระบุที่อยู่';
  String _recipientImageUrl = ''; // เริ่มต้นเป็นค่าว่าง

  @override
  void initState() {
    super.initState();
    // นำข้อมูลที่ได้รับมาใส่ใน State
    _recipientName = widget.recipientData['name'] ?? _recipientName;
    _recipientPhone = widget.recipientData['phone'] ?? _recipientPhone;
    _recipientAddress = widget.recipientData['address'] ?? _recipientAddress;
    _recipientImageUrl = widget.recipientData['imageUrl'] ?? _recipientImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // กลับไปหน้า search
          },
        ),
        title: const Text(
          'ส่งสินค้า',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.15),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- การ์ดข้อมูลผู้ใช้ (แสดงข้อมูลจริง) ---
            _buildUserInfoCard(),
            const SizedBox(height: 24),

            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Center(
                child: Text(
                  'แนบข้อมูลสินค้าที่จะส่ง',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              height: 150,
              width: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 60,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageActionButton(
                  label: 'อัปโหลดรูปสินค้า',
                  icon: Icons.add_photo_alternate_outlined,
                  color: primaryColor,
                ),
                _buildImageActionButton(
                  label: 'ถ่ายรูปสินค้า',
                  icon: Icons.camera_alt_outlined,
                  color: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'รายละเอียดสินค้า :',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'เพิ่ม',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildItemList(),
            const SizedBox(height: 24),
            _buildSaveButton(context),
            // vvvv ส่วนที่เพิ่มเข้ามา vvvv
            const SizedBox(height: 32), // <-- เพิ่มระยะห่างก่อนรายการสินค้า
            _buildItemList(), // <-- เรียกใช้ฟังก์ชันสร้างรายการสินค้า
            const SizedBox(height: 24), // <-- เพิ่มระยะห่างก่อนปุ่มบันทึก
            _buildSaveButton(context), // <-- เรียกใช้ฟังก์ชันสร้างปุ่มบันทึก
            // ^^^^ จบส่วนที่เพิ่ม ^^^^

          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: (_recipientImageUrl.isNotEmpty)
                ? NetworkImage(_recipientImageUrl)
                : null,
            child: (_recipientImageUrl.isEmpty)
                ? const Icon(Icons.person, size: 35, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ชื่อ', _recipientName),
                const SizedBox(height: 4),
                _buildInfoRow('หมายเลขโทรศัพท์', _recipientPhone),
                const SizedBox(height: 4),
                _buildInfoRow('ที่อยู่', _recipientAddress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Text.rich(
      TextSpan(
        text: '$label : ',
        style: TextStyle(color: Colors.grey.shade600),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildImageActionButton({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }

  Widget _buildItemList() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildItemCard(
            imageUrl: "https://i.imgur.com/kS9YnSg.png",
            description: "เสื้อยืดแขนยาวสีดำ",
          ),
          const Divider(height: 16, thickness: 1),
          _buildItemCard(
            imageUrl: "https://i.imgur.com/3Z0NpyA.png",
            description: "รองเท้า Nike",
          ),
          const Divider(height: 16, thickness: 1),
          _buildItemCard(
            imageUrl: "https://i.imgur.com/kS9YnSg.png",
            description: "เสื้อยืดแขนยาวสีดำ",
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({
    required String imageUrl,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "รายละเอียดสินค้า:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    const Color greenColor = Colors.green;
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReceivePage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: greenColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: const Text(
        'บันทึก',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146),
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryPage()),
              (Route<dynamic> route) => false,
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MoreOptionsPage()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'ประวัติการส่งสินค้า',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'อื่นๆ'),
      ],
    );
  }
}