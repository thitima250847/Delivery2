import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StatusScreen extends StatefulWidget {
  final String packageId; // รับ ID งานที่ต้องการติดตาม
  const StatusScreen({super.key, required this.packageId}); 
// vvv เปลี่ยนชื่อคลาสเป็น StatusScreen
class StatusScreen extends StatelessWidget {
  // vvv อัปเดต Constructor
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  static const Color primaryYellow = Color(0xFFFDE100);
  static const Color darkGreen = Color(0xFF98C21D); // สีเขียวสำหรับ Active
  static const Color lightGrey = Color(0xFF9E9E9E); // สีเทาสำหรับ Inactive

  // ข้อมูลสถานะที่ดึงจาก Firestore (ต้องตรงกับ field ใน TrackingScreen.dart)
  String _currentPackageStatus = 'pending'; 
  
  // ข้อมูลไรเดอร์ที่ดึงมาแสดงผล
  String _riderName = 'กำลังโหลด...';
  String _riderPhone = 'กำลังโหลด...';
  String _riderPlate = 'กำลังโหลด...';
  String _riderImageUrl = 'https://via.placeholder.com/60?text=Rider'; // Fallback image
  
  // ข้อมูลสินค้า
  String _productImageUrl = "https://via.placeholder.com/80?text=Product";
  String _productDescription = 'กำลังโหลดรายละเอียด...';
  
  // ข้อมูลยืนยันการส่งสินค้า
  String? _proofPhoto1Url;
  String? _proofPhoto2Url;

  int _navIndex = 0; // ตัวแปรสำหรับ Bottom Navigation


  @override
  void initState() {
    super.initState();
    _fetchPackageStatus();
  }

  // ฟังก์ชันดึงสถานะและข้อมูลไรเดอร์จาก Firestore
  void _fetchPackageStatus() {
    FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.packageId)
        .snapshots() 
        .listen((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) {
        if (mounted) {
          setState(() {
            _currentPackageStatus = 'not_found';
            _riderName = 'ไม่พบงานที่กำลังส่ง';
            _productDescription = '';
          });
        }
        return;
      }
      
        final data = snapshot.data()!;
        
        String tempRiderName = 'รอไรเดอร์รับงาน';
        String tempRiderPhone = 'รอไรเดอร์รับงาน';
        String tempRiderPlate = 'รอไรเดอร์รับงาน';
        String tempRiderImageUrl = 'https://i.imgur.com/gX3tYlI.png';
        
        if (data['rider_id'] != null && data['status'] != 'pending') {
            tempRiderName = 'Rider: ${data['rider_id'].substring(0, 6)}...';
            // ในการใช้งานจริง: ต้องดึงข้อมูลเบอร์โทรและทะเบียนรถจาก Collection 'users'
            tempRiderPhone = data['rider_phone'] ?? '09x-xxx-xxxx'; 
            tempRiderPlate = data['rider_plate'] ?? '7กxxx-xxx'; 
        }

        setState(() {
          _currentPackageStatus = data['status'] ?? 'pending';

          // ดึงข้อมูลสินค้าและรูปถ่ายยืนยัน
          _productDescription = data['package_description'] ?? 'ไม่ระบุรายละเอียด';
          _productImageUrl = data['proof_image_url'] ?? "https://via.placeholder.com/80?text=Product"; 
          _proofPhoto1Url = data['proof_image_url_1'];
          _proofPhoto2Url = data['proof_image_url_2'];
          
          // อัปเดตข้อมูลไรเดอร์ที่แสดงผล
          _riderName = tempRiderName;
          _riderPhone = tempRiderPhone;
          _riderPlate = tempRiderPlate;
          _riderImageUrl = tempRiderImageUrl;
        });
      
    });
  }

  // กำหนด Active Step ตามสถานะ Firestore
  int _getActiveStep() {
    switch (_currentPackageStatus) {
      case 'accepted': return 2; // ไรเดอร์รับงานแล้ว
      case 'on_delivery': return 3; // กำลังเดินทางส่งสินค้า
      case 'delivered': return 4; // ส่งสินค้าเสร็จสิ้น
      case 'pending': default: return 1; // รอนานรับออเดอร์สินค้า
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = _getActiveStep();
    final isRiderAssigned = activeStep >= 2;
    final isDelivered = activeStep == 4;
    final isNotFound = _currentPackageStatus == 'not_found';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        toolbarHeight: 90.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
        title: const Text(
          "สถานะการจัดส่งสินค้า",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isNotFound
          ? const Center(child: Text("ไม่พบงานที่กำลังส่ง", style: TextStyle(fontSize: 18, color: Colors.black54)))
          : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. ตัวติดตามสถานะ (Stepper)
                  _buildStepper(activeStep),
                  const SizedBox(height: 32),

                  // 2. แสดงรายละเอียดสินค้า (ใช้ข้อมูลจริง)
                  _buildProductHeader(),
                  const SizedBox(height: 16),
                  _buildProductImage(_productImageUrl, _productDescription),
                  const SizedBox(height: 24),

                  // 3. ข้อมูลไรเดอร์ (ใช้ข้อมูลจริง)
                  if (isRiderAssigned)
                    _buildRiderInfoCard()
                  else
                    _buildWaitingRiderCard(),
                  
                  if (isDelivered && (_proofPhoto1Url != null || _proofPhoto2Url != null))
                    _buildProofSection(), // แสดงรูปถ่ายยืนยันเมื่อส่งสำเร็จ
                  
                  const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  /// --- WIDGET BUILDERS --- ///

  Widget _buildProductHeader() {
    return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: const Color(0xFFFFD900),
                width: 1.5,
              ),
            ),
            child: const Text(
              "สินค้าที่จะส่ง",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFA6A000),
              ),
            ),
          ),
        );
  }

  Widget _buildProductImage(String imageUrl, String description) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รายละเอียด:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    description.isEmpty ? 'ไม่ระบุรายละเอียดสินค้า' : description,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRiderInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ข้อมูลไรเดอร์ที่รับงาน",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(_riderImageUrl),
              radius: 28,
            ),
            title: Text(
              "ชื่อ : $_riderName",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "หมายเลขโทรศัพท์ : $_riderPhone",
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  "หมายเลขทะเบียนรถ : $_riderPlate",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingRiderCard() {
     return Card(
        color: Colors.grey[100],
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'รอไรเดอร์รับงาน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          "รูปถ่ายยืนยันการจัดส่ง (Rider)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildProofImageCard(_proofPhoto1Url, "รูปที่ 1"),
              const SizedBox(width: 16),
              _buildProofImageCard(_proofPhoto2Url, "รูปที่ 2"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProofImageCard(String? imageUrl, String label) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl == null
            ? Center(
                child: Text(label, style: const TextStyle(color: Colors.grey)),
              )
            : null,
      ),
    );
  }

  /// Widget สำหรับสร้างตัวติดตามสถานะ (Stepper)
  Widget _buildStepper(int activeStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepItem(
          Icons.hourglass_top_rounded,
          "รอรับออเดอร์สินค้า",
          activeStep >= 1, // Active เสมอ
        ),
        _buildStepConnector(activeStep >= 2),
        _buildStepItem(
          Icons.assignment_turned_in_outlined,
          "ไรเดอร์รับงาน",
          activeStep >= 2,
        ),
        _buildStepConnector(activeStep >= 3),
        _buildStepItem(
          Icons.delivery_dining_outlined,
          "กำลังเดินทางส่งสินค้า",
          activeStep >= 3,
        ),
        _buildStepConnector(activeStep >= 4),
        _buildStepItem(
          Icons.check_circle_outline_rounded,
          "ส่งสินค้าเสร็จสิ้น",
          activeStep >= 4,
        ),
      ],
    );
  }

  /// Widget สำหรับสร้าง 1 ไอคอนใน Stepper
  Widget _buildStepItem(IconData icon, String label, bool isActive) {
    final Color iconBackgroundColor = isActive ? primaryYellow : Colors.grey.shade100;
    final Color iconColor = isActive ? darkGreen : lightGrey;
    final Color borderColor = isActive ? darkGreen : lightGrey;

    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBackgroundColor,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget สำหรับสร้างเส้นเชื่อมระหว่าง Step
  Widget _buildStepConnector(bool isActive) {
    final Color connectorColor = isActive ? darkGreen : lightGrey;
    
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Container(height: 3, color: connectorColor),
          const SizedBox(
            height: 42,
          ), // จัดตำแหน่งให้อยู่ตรงกลาง (SizedBox + Text)
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    
    return BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: Colors.white,
        selectedItemColor: primaryYellow,
        unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
        onTap: (index) {
          if (index == 0) {
            // กลับไปหน้าแรก (DeliveryPage) โดยล้าง Stack
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DeliveryPage()),
                (route) => false,
            );
          } else if (index == 1) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
          } else if (index == 2) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const MoreOptionsPage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'ประวัติการส่งสินค้า'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'อื่นๆ'),
        ],
    );
  }
}
