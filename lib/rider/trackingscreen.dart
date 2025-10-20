import 'package:flutter/material.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const Color primaryGreen = Color(0xFF98C21D);
  static const Color darkGreenText = Color(0xFF98C21D);

  final int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24.0),
            _buildMap(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 8),
            _buildTabContent(),
            _buildSectionTitle("ข้อมูลสินค้า"),
            const SizedBox(height: 16),
            _buildProductCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// --- WIDGET BUILDERS --- ///

  /// แก้ไข Widget นี้เพื่อเพิ่มปุ่มย้อนกลับ ///
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: const BoxDecoration(color: Color(0xFFEDE500)),
      child: Stack(
        // 1. ใช้ Stack เพื่อให้วาง Widget ซ้อนกันได้
        children: [
          // 2. เนื้อหาเดิม (จัดให้อยู่ตรงกลาง)
          Column(
            children: [
              _buildPageTitle("สถานะการจัดส่งสินค้า"),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildStepItem(
                      Icons.hourglass_top_rounded,
                      "รอรับออเดอร์สินค้า",
                      true,
                    ),
                    _buildStepConnector(true),
                    _buildStepItem(
                      Icons.assignment_turned_in_outlined,
                      "ไรเดอร์รับงาน",
                      true,
                    ),
                    _buildStepConnector(true),
                    _buildStepItem(
                      Icons.delivery_dining_outlined,
                      "กำลังเดินทางส่งสินค้า",
                      true,
                      isCurrent: true,
                    ),
                    _buildStepConnector(false),
                    _buildStepItem(
                      Icons.check_circle_outline_rounded,
                      "ส่งสินค้าเสร็จสิ้น",
                      false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 3. ปุ่มย้อนกลับ (วางไว้มุมบนซ้าย)
          Positioned(
            top: 0, // จัดตำแหน่งปุ่มให้อยู่ในระยะที่เหมาะสม
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
              onPressed: () {
                // คำสั่งย้อนกลับไปหน้าก่อนหน้า
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFEDE500),
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStepItem(
    IconData icon,
    String label,
    bool isActive, {
    bool isCurrent = false,
  }) {
    final Color color = isActive ? darkGreenText : Colors.grey.shade400;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 3,
            color: isActive ? darkGreenText : Colors.grey.shade400,
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: darkGreenText,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Image.network(
          "https://i.imgur.com/3Z0NpyA.png",
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTabItem("สถานะกำลังส่ง", 0),
          const SizedBox(width: 10),
          _buildTabItem("นำส่งสินค้าแล้ว", 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: darkGreenText,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      return Column(
        children: [
          _buildPhotoUploaders(),
          const SizedBox(height: 16),
          _buildAddressCard(),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: const Center(
          child: Text(
            "ยังไม่มีข้อมูลการนำส่งสินค้า",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildPhotoUploaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildPhotoPlaceholder(),
          const SizedBox(width: 16),
          _buildPhotoPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: const Center(
          child: Icon(Icons.camera_alt_rounded, color: primaryGreen, size: 45),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              "https://i.imgur.com/28h2Lna.png",
              width: 60,
              height: 60,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildAddressInfo(
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    title: "คณะวิทยาการสารสนเทศ",
                    name: "Thitima",
                    phone: "0655764805",
                    labelPrefix: "ชื่อผู้ส่ง",
                  ),
                  const SizedBox(height: 16),
                  _buildAddressInfo(
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    title: "หอพักเรืองรองริเวอร์วิว",
                    name: "Kanokwan Laptawee",
                    phone: "0987654321",
                    labelPrefix: "ชื่อผู้รับ",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String phone,
    required String labelPrefix,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                "$labelPrefix : $name",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "เบอร์โทรศัพท์ : $phone",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                "https://i.imgur.com/kS9YnSg.png",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "รายละเอียดสินค้า:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "เสื้อยืดแขนยาวสีดำ",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
