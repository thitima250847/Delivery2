import 'package:delivery/user/senditem.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ลบ import 'package:delivery/config/config_Img.dart' hide Config; ออก

class SearchRecipientScreen extends StatefulWidget {
  const SearchRecipientScreen({Key? key}) : super(key: key);

  @override
  State<SearchRecipientScreen> createState() => _SearchRecipientScreenState();
}

class _SearchRecipientScreenState extends State<SearchRecipientScreen> {
  static const Color primaryYellow = Color(0xFFFDE100);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  String? _myPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadMyAvatar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // --- ลบฟังก์ชัน _resolveImageUrl ออก ---

  Future<void> _loadMyAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (mounted && data != null) {
        setState(() {
          // --- แก้ไข: ใช้ URL จาก Firestore โดยตรง ---
          _myPhotoUrl = data['profile_image'] as String?;
        });
      }
    } catch (_) {
      // Handle error silently
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone_number', isGreaterThanOrEqualTo: query)
          .where('phone_number', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      List<Map<String, dynamic>> users = querySnapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String addressText = 'ไม่ระบุที่อยู่';
            if (data['addresses'] != null &&
                (data['addresses'] as List).isNotEmpty) {
              addressText =
                  (data['addresses'][0]
                          as Map<String, dynamic>)['address_text'] ??
                      'ไม่ระบุที่อยู่';
            }
            data['address'] = addressText;
            
            // --- แก้ไข: ไม่ต้อง resolve URL แล้ว ---
            // Firestore มี URL ที่สมบูรณ์จาก Cloudinary อยู่แล้ว
            // เราแค่ต้องแน่ใจว่าค่าที่ได้เป็น String
            data['profile_image'] = data['profile_image'] as String? ?? '';

            return data;
          })
          .toList();

      setState(() {
        _searchResults = users;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาดในการค้นหา: $e");
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        toolbarHeight: 90.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade300,
              // --- แก้ไข: ตรวจสอบ _myPhotoUrl ที่อาจเป็น null หรือ "" ---
              backgroundImage:
                  (_myPhotoUrl != null && _myPhotoUrl!.isNotEmpty) ? NetworkImage(_myPhotoUrl!) : null,
              child: (_myPhotoUrl == null || _myPhotoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.black54, size: 28)
                  : null,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              onChanged: (value) {
                _searchUsers(value);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
                  },
                ),
                filled: true,
                fillColor: Colors.grey[200],
                hintText: "กรอกเบอร์โทรศัพท์ผู้รับ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'กรุณาค้นหาด้วยเบอร์โทรศัพท์'
                                : 'ไม่พบผู้ใช้',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return _buildContactTile(context, user: user);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required Map<String, dynamic> user,
  }) {
    final String name = user['name'] ?? 'ไม่มีชื่อ';
    final String phone = user['phone_number'] ?? 'ไม่มีเบอร์';
    final String address = user['address'] ?? 'ไม่ระบุที่อยู่';
    final String? imageUrl = user['profile_image'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade300,
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    // --- แก้ไข: ไม่ต้องต่อ String แล้ว ---
                    imageUrl, 
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Colors.white);
                    },
                  ),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          phone,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            final recipientData = {
              'name': name,
              'phone': phone,
              'address': address,
              'imageUrl': imageUrl ?? '',
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SendItemPage(recipientData: recipientData),
              ),
            );
          },
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