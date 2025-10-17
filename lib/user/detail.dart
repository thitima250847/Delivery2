import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart' hide CustomAppBarClipper;
import 'package:delivery/user/tracking.dart' hide CustomAppBarClipper;
import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // สีพื้นหลังเทาอ่อน
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: ClipPath(
          clipper: CustomAppBarClipper(borderRadius: 20.0),
          child: AppBar(
            backgroundColor: const Color(0xFFFDE428),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                // ใส่โค้ดสำหรับย้อนกลับที่นี่
              },
            ),
            title: const Text(
              'รายละเอียดสินค้า',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // การ์ดสินค้าใบที่ 1
            _buildDetailCard(
              trackingId: '#16623666',
              sender: 'XXX',
              recipientName: 'พิ๊ฟิ',
              recipientAddress:
                  '999 หมู่ 10 อ.เมืองหนึ่ง ต.หนึ่งแห่ง จ.มหาสารคาม 525456',
              recipientPhone: '0899999999',
              imagePlaceholderColor: Colors.grey.shade300, // สีของรูปสินค้า
              driverName: 'thitima',
              shippingDate: '21/9/2567 เวลา 10:00',
              deliveryDate: '21/9/2567 เวลา 12:00',
            ),
            const SizedBox(height: 16),
            // การ์ดสินค้าใบที่ 2
            _buildDetailCard(
              trackingId: '#16623666',
              sender: 'XXX',
              recipientName: 'พิ๊ฟิ',
              recipientAddress:
                  '999 หมู่ 10 อ.เมืองหนึ่ง ต.หนึ่งแห่ง จ.มหาสารคาม 525456',
              recipientPhone: '0899999999',
              imagePlaceholderColor: Colors.black26, // สีของรูปสินค้า
              driverName: 'thitima',
              shippingDate: '21/9/2567 เวลา 10:00',
              deliveryDate: '21/9/2567 เวลา 12:00',
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // --- ฟังก์ชันสำหรับสร้างการ์ดรายละเอียดสินค้า ---
  Widget _buildDetailCard({
    required String trackingId,
    required String sender,
    required String recipientName,
    required String recipientAddress,
    required String recipientPhone,
    required Color imagePlaceholderColor,
    required String driverName,
    required String shippingDate,
    required String deliveryDate,
  }) {
    const textStyleLabel = TextStyle(color: Colors.black54, fontSize: 14);
    const textStyleValue = TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ส่วน Tracking ID ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tracking ID', style: textStyleLabel),
                  Text(
                    trackingId,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text('ผู้ส่ง : $sender', style: textStyleValue),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          // --- ส่วนข้อมูลผู้รับ ---
          Text('ผู้รับ : $recipientName', style: textStyleValue),
          const SizedBox(height: 4),
          Text('ที่อยู่ผู้รับ : $recipientAddress', style: textStyleValue),
          const SizedBox(height: 4),
          Text('โทรศัพท์ : $recipientPhone', style: textStyleValue),
          const Divider(height: 24, thickness: 1),

          // --- ส่วนสิ่งของทั้งหมด ---
          const Text('สิ่งของทั้งหมด', style: textStyleValue),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: imagePlaceholderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              // child: Image.asset('path/to/your_image.png'), // หากมีรูปภาพจริง
            ),
          ),
          const SizedBox(height: 12),
          Text('คนขับ : $driverName', style: textStyleValue),
          const SizedBox(height: 4),
          Text('จัดส่งวันที่ : $shippingDate', style: textStyleValue),
          const SizedBox(height: 4),
          Text('ส่งถึงผู้รับ : $deliveryDate', style: textStyleValue),
        ],
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeliveryPage()),
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
