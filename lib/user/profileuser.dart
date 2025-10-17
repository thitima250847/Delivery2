import 'package:flutter/material.dart';

// (You can delete main() and MyApp() if integrating into an existing project)

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  // Main yellow color
  static const Color primaryYellow = Color(0xFFFDE428);
  // Background color for input fields
  static const Color fieldBgColor = Color(0xFFF5F5F5);
  // Green color for the plus icon
  static const Color plusGreen = Color(0xFF28C76F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(context), // Using the custom AppBar
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // 1. Profile Picture
              _buildProfilePicture(),
              const SizedBox(height: 24.0),

              // 2. Info Fields
              _buildInfoField(icon: Icons.person_outline, text: "fiwfy"),
              const SizedBox(height: 12.0),
              _buildInfoField(
                icon: Icons.person_outline,
                text: "fiwfy@gmail.com",
              ),
              const SizedBox(height: 12.0),
              _buildInfoField(icon: Icons.phone_outlined, text: "0888888888"),
              const SizedBox(height: 12.0),
              _buildInfoField(
                icon: Icons.lock_outline,
                text: "********",
                trailingIcon: Icons.visibility_outlined,
              ),
              const SizedBox(height: 12.0),
              _buildInfoField(
                icon: Icons.location_on_outlined,
                text: "หมู่บ้านอัครฉัตรธานี",
              ),
              const SizedBox(height: 12.0),
              _buildInfoField(
                icon: Icons.location_on_outlined,
                text: "ที่อยู่ใหม่",
              ),
              const SizedBox(height: 24.0),

              // 3. Plus icon at the bottom
              const Icon(Icons.add, color: Colors.black, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget for building the curved AppBar (Corrected)
  PreferredSize _buildCustomAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = 100;

    return PreferredSize(
      preferredSize: const Size.fromHeight(appBarHeight),
      child: ClipPath(
        clipper: CustomAppBarClipper(borderRadius: 30.0),
        child: Container(
          color: primaryYellow,
          padding: EdgeInsets.only(top: statusBarHeight),
          child: Center(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                // vvvv This was the error location vvvv
                // The extra closing parenthesis was here
                const SizedBox(width: 10),
                const Text(
                  'ข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // ^^^^ Corrected structure ^^^^
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget for building the profile picture
  Widget _buildProfilePicture() {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          clipBehavior: Clip.none, // Allow icon to overflow
          children: [
            // Profile image
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                "https://i.imgur.com/v8SjA9H.png",
              ), // (Using Shiba as placeholder)
            ),
            // Green plus icon
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: plusGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget for building an info field row
  Widget _buildInfoField({
    required IconData icon,
    required String text,
    IconData? trailingIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                // (Use a font that shows thick dots for passwords)
                fontFamily: (text == "********") ? 'Roboto' : null,
              ),
            ),
          ),
          if (trailingIcon != null) Icon(trailingIcon, color: Colors.grey[700]),
        ],
      ),
    );
  }
}

/// Class for clipping the AppBar (must be in this file)
class CustomAppBarClipper extends CustomClipper<Path> {
  final double borderRadius;
  CustomAppBarClipper({this.borderRadius = 20.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - borderRadius);
    path.quadraticBezierTo(0, size.height, borderRadius, size.height);
    path.lineTo(size.width - borderRadius, size.height);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - borderRadius,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
