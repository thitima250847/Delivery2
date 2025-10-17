import 'package:delivery/user/detail.dart';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/search.dart';
import 'package:delivery/user/status.dart'; // <-- Make sure StatusScreen is imported
import 'package:flutter/material.dart';

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          _buildCustomAppBar(), // AppBar at the back
          // Scrollable content area, pushed down
          Padding(
            padding: const EdgeInsets.only(
              top: 180.0,
            ), // Adjust top padding if AppBar height changes
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 130.0,
              ), // Space for the action buttons
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildContentTitle(), // "รายการสินค้าที่ต้องรับ" title
                    const SizedBox(height: 24),
                    // Delivery card 1
                    _buildDeliveryCard(
                      context,
                      senderLocation: 'หอพักอัครฉัตรแมนชั่น ตึกใหม่',
                      senderName: 'sathima kanlayasai',
                      recipientLocation: 'คณะวิทยาการสารสนเทศ',
                      recipientName: 'Soduku',
                    ),
                    const SizedBox(height: 16),
                    // Delivery card 2
                    _buildDeliveryCard(
                      context,
                      senderLocation: 'หอพักอัครฉัตรแมนชั่น ตึกใหม่',
                      senderName: 'sathima kanlayasai',
                      recipientLocation: 'คณะวิทยาการสารสนเทศ',
                      recipientName: 'Soduku',
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Add some bottom padding if needed
                  ],
                ),
              ),
            ),
          ),
          // Action buttons positioned over the AppBar and content
          Positioned(
            top: 150, // Position buttons below the main AppBar content
            // Ensure the buttons container doesn't overflow horizontally
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      context: context,
                      label: 'ส่งสินค้า',
                      icon: Icons.send_rounded,
                      iconColor: Colors.blue.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SearchRecipientScreen(), // Navigate to Search Screen
                          ),
                        );
                        print('กดปุ่ม: ส่งสินค้า');
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      context: context,
                      label: 'สินค้าที่กำลังส่ง',
                      icon: Icons.local_shipping,
                      iconColor: Colors.orange.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const StatusScreen(), // Navigate to Status Screen
                          ),
                        );
                        print('กดปุ่ม: สินค้าที่กำลังส่ง');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context: context,
                  label: 'สินค้าที่ต้องรับ',
                  icon: Icons.inventory_2,
                  iconColor: Colors.green.shade700,
                  onTap: () {
                    // Current page, do nothing or maybe refresh
                    print('กดปุ่ม: สินค้าที่ต้องรับ');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // --- AppBar ---
  Widget _buildCustomAppBar() {
    return ClipPath(
      clipper: CustomAppBarClipper(
        borderRadius: 30.0,
      ), // Apply clipping with border radius
      child: Container(
        // Adjusted height to better fit content, can be tweaked
        height: 290, // <--- Adjust height if needed
        width: double.infinity,
        color: const Color(0xFFFEE146), // Yellow background
        child: SafeArea(
          bottom: false, // No padding at the bottom inside SafeArea
          child: Padding(
            padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
            child: Column(
              children: [
                // Top row: Greeting and Profile Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'สวัสดี Tester',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.3,
                        ), // Semi-transparent white
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Address Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA9A9A9), // Grey background
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Row(
                    // vvvv Center the icon and text vvvv
                    mainAxisAlignment: MainAxisAlignment.center,
                    // ^^^^ ^^^^
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      // Use Flexible to prevent long text overflow
                      Flexible(
                        child: const Text(
                          'หอพักอัจฉราแมนชั่น ตึกใหม่',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Add ellipsis (...) if text is too long
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Action Button ---
  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        15,
      ), // Match Container's border radius
      child: Container(
        width: 190, // Adjusted width
        padding: const EdgeInsets.symmetric(
          vertical: 16.0,
        ), // Vertical padding for height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            10,
          ), // Slightly less rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 5), // Shadow position
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ), // Adjusted font size
            ),
            const SizedBox(width: 8),
            Icon(icon, color: iconColor, size: 26), // Adjusted icon size
          ],
        ),
      ),
    );
  }

  // --- Content Title ("รายการสินค้าที่ต้องรับ") ---
  Widget _buildContentTitle() {
    return Container(
      width: double.infinity, // Make title container stretch full width
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.yellow.shade700,
          width: 1.5,
        ), // Yellow border
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'รายการสินค้าที่ต้องรับ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- Delivery Card ---
  Widget _buildDeliveryCard(
    BuildContext context, {
    required String senderLocation,
    required String senderName,
    required String recipientLocation,
    required String recipientName,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Align items vertically center
        children: [
          // Delivery Icon Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Light grey background
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delivery_dining, // Delivery icon
              size: 40,
              color: Colors.green.shade700, // Green icon color
            ),
          ),
          const SizedBox(width: 16),
          // Location and Name Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(
                  icon: Icons.location_on,
                  color: Colors.red, // Red for sender
                  location: senderLocation,
                  person: 'ชื่อผู้ส่ง : $senderName',
                ),
                const SizedBox(height: 12),
                _buildLocationRow(
                  icon: Icons.location_on,
                  color: Colors.green, // Green for recipient
                  location: recipientLocation,
                  person: 'ชื่อผู้รับ : $recipientName',
                ),
                const SizedBox(height: 12),
                // Details Button aligned to the right
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DetailPage(), // Navigate to Detail Page
                        ),
                      );
                      print('กดปุ่ม รายละเอียด');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE428), // Yellow button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 0, // No shadow
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, // Fit content size
                      children: [
                        Text(
                          'รายละเอียด',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right, // Right arrow icon
                          color: Colors.black,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Location Row Helper ---
  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String location,
    required String person,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align icon and text top
      children: [
        Icon(icon, color: color, size: 20), // Location icon
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Text
              Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              // Person Name Text
              Text(
                person,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ), // Greyish text
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFFEE146), // Yellow for selected item
      unselectedItemColor: const Color.fromARGB(
        255,
        20,
        19,
        19,
      ), // Dark grey for unselected
      currentIndex: 0, // Assuming this page is the first tab (index 0)
      onTap: (index) {
        // Handle navigation
        Widget page;
        bool shouldReplace = true; // Use pushReplacement by default

        switch (index) {
          case 0:
            // Already on this page, do nothing or maybe refresh
            return; // Exit if already on the current page
          case 1:
            page = const HistoryPage();
            shouldReplace = false; // Use push for History so user can go back
            break;
          case 2:
            page = const MoreOptionsPage();
            shouldReplace =
                false; // Use push for More Options so user can go back
            break;
          default:
            return; // Should not happen
        }

        if (shouldReplace) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
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
} // End of ReceivePage class

// --- Custom Clipper for AppBar ---
class CustomAppBarClipper extends CustomClipper<Path> {
  final double borderRadius;
  CustomAppBarClipper({this.borderRadius = 30.0}); // Default border radius

  @override
  Path getClip(Size size) {
    // Path creation logic for curved bottom AppBar
    final path = Path();
    path.lineTo(0, size.height - borderRadius); // Start line
    // Quadratic Bezier curve for left corner
    path.quadraticBezierTo(0, size.height, borderRadius, size.height);
    // Line across bottom
    path.lineTo(size.width - borderRadius, size.height);
    // Quadratic Bezier curve for right corner
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - borderRadius,
    );
    // Line up right side
    path.lineTo(size.width, 0);
    path.close(); // Close path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true; // Always reclip (can be optimized if needed)
}
