import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/map/map_register.dart'; // Import the map picker screen
import 'package:latlong2/latlong.dart' as latlong;

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Main colors
  static const Color primaryYellow = Color(0xFFFDE428);
  static const Color fieldBgColor = Color(0xFFF5F5F5);
  static const Color plusGreen = Color(0xFF28C76F);

  // State variables
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<dynamic> _userAddresses = [];

  bool _isAddingAddress = false;
  final TextEditingController _newAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _newAddressController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  // --- 1. Fetch user data from Firestore ---
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle not logged in case
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _userAddresses = _userData?['addresses'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้");
    }
  }
  
  // --- 2. Navigate to map and handle result ---
  Future<void> _selectAddressFromMap() async {
    // Navigate to the map picker screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    // Handle the result from the map picker
    if (result != null && result is Map) {
      final latlong.LatLng? pickedLocation = result['location'];
      final String? pickedAddress = result['address'];

      if (pickedLocation != null && pickedAddress != null) {
        _newAddressController.text = pickedAddress;
        // Automatically save the new address
        _saveNewAddress(pickedAddress, pickedLocation);
      }
    }
  }

  // --- 3. Save the new address to Firestore ---
  Future<void> _saveNewAddress(String addressText, latlong.LatLng location) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (addressText.isEmpty) {
      _showSnack("กรุณาเลือกที่อยู่");
      return;
    }

    final newAddress = {
      'address_text': addressText,
      'gps': {'lat': location.latitude, 'lng': location.longitude},
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'addresses': FieldValue.arrayUnion([newAddress])
      });
      _showSnack("บันทึกที่อยู่ใหม่สำเร็จ!", isSuccess: true);
      
      // Hide the input field and refresh data
      setState(() {
        _isAddingAddress = false;
        _newAddressController.clear();
      });
      _fetchUserData(); // Refresh user data to show the new address

    } catch (e) {
      _showSnack("เกิดข้อผิดพลาดในการบันทึกที่อยู่");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text("ไม่พบข้อมูลผู้ใช้"))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      children: [
                        _buildProfilePicture(_userData?['profile_image']),
                        const SizedBox(height: 24.0),

                        // --- 4. Display real data ---
                        _buildInfoField(icon: Icons.person_outline, text: _userData?['name'] ?? 'ไม่มีชื่อ'),
                        const SizedBox(height: 12.0),
                        _buildInfoField(icon: Icons.mail_outline, text: _userData?['user_email'] ?? 'ไม่มีอีเมล'),
                        const SizedBox(height: 12.0),
                        _buildInfoField(icon: Icons.phone_outlined, text: _userData?['phone_number'] ?? 'ไม่มีเบอร์โทร'),
                        const SizedBox(height: 12.0),
                        _buildInfoField(
                          icon: Icons.lock_outline,
                          text: "********",
                          trailingIcon: Icons.visibility_outlined,
                        ),
                        const SizedBox(height: 12.0),

                        // --- 5. Display list of addresses ---
                        ..._userAddresses.map((address) {
                           final addressText = (address as Map)['address_text'] ?? 'ที่อยู่ไม่ถูกต้อง';
                           return Padding(
                             padding: const EdgeInsets.only(bottom: 12.0),
                             child: _buildInfoField(
                               icon: Icons.location_on_outlined,
                               text: addressText,
                             ),
                           );
                        }).toList(),

                        // --- 6. Show/Hide new address field ---
                        if (_isAddingAddress)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildInfoField(
                              icon: Icons.location_on_outlined,
                              text: "คลิกเพื่อเลือกที่อยู่ใหม่",
                              isButton: true,
                              controller: _newAddressController,
                              onTap: _selectAddressFromMap, // Assign the function here
                            ),
                          ),
                        
                        const SizedBox(height: 24.0),

                        // --- 7. Plus button to toggle address field ---
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAddingAddress = !_isAddingAddress;
                            });
                          },
                          child: Icon(
                            _isAddingAddress ? Icons.remove : Icons.add, 
                            color: Colors.black, 
                            size: 30
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  PreferredSize _buildCustomAppBar(BuildContext context) {
    // ... (This widget is correct, no changes needed)
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
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture(String? imageUrl) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) 
                  ? NetworkImage(imageUrl) 
                  : null,
              child: (imageUrl == null || imageUrl.isEmpty) 
                  ? const Icon(Icons.person, size: 60, color: Colors.white) 
                  : null,
            ),
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

  Widget _buildInfoField({
    required IconData icon,
    required String text,
    IconData? trailingIcon,
    bool isButton = false,
    VoidCallback? onTap,
    TextEditingController? controller,
  }) {
    return InkWell(
      onTap: isButton ? onTap : null,
      child: IgnorePointer(
        ignoring: !isButton,
        child: TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: text,
            prefixIcon: Icon(icon, color: Colors.grey[700]),
            suffixIcon: trailingIcon != null ? Icon(trailingIcon, color: Colors.grey[700]) : null,
            filled: true,
            fillColor: fieldBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
             focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(color: primaryYellow, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          ),
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[800],
            fontFamily: (text == "********") ? 'Roboto' : null,
          ),
        ),
      ),
    );
  }
}

class CustomAppBarClipper extends CustomClipper<Path> {
  // ... (This class is correct, no changes needed)
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