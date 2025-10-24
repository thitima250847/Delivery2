import 'package:delivery/user/senditem.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchRecipientScreen extends StatefulWidget {
  const SearchRecipientScreen({super.key});

  @override
  State<SearchRecipientScreen> createState() => _SearchRecipientScreenState();
}

class _SearchRecipientScreenState extends State<SearchRecipientScreen> {
  static const Color primaryYellow = Color(0xFFFDE100);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allUsers = []; // <-- ADDED: เก็บรายชื่อผู้ใช้ทั้งหมด
  List<Map<String, dynamic>> _searchResults = []; // <-- ใช้สำหรับแสดงผล
  bool _isLoading = true; // <-- MODIFIED: เปลี่ยนเป็น isLoading สำหรับการโหลดครั้งแรก

  String? _myPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadMyAvatar();
    _fetchAllUsers(); // <-- ADDED: เรียกฟังก์ชันโหลดผู้ใช้ทั้งหมดตอนเริ่ม
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (mounted && data != null) {
        setState(() {
          _myPhotoUrl = data['profile_image'] as String?;
        });
      }
    } catch (_) {}
  }

  // --- 1. สร้างฟังก์ชันสำหรับดึงผู้ใช้ทั้งหมด ---
  Future<void> _fetchAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> users = querySnapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['user_id'] = doc.id;
            
            String addressText = 'ไม่ระบุที่อยู่';
            if (data['addresses'] != null && (data['addresses'] as List).isNotEmpty) {
              addressText = (data['addresses'][0] as Map<String, dynamic>)['address_text'] ?? 'ไม่ระบุที่อยู่';
            }
            data['address'] = addressText;
            data['profile_image'] = data['profile_image'] as String? ?? '';
            return data;
          }).toList();

      setState(() {
        _allUsers = users;
        _searchResults = users; // ตอนแรกให้ผลลัพธ์การค้นหาเป็น user ทั้งหมด
      });
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้ทั้งหมด: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. แก้ไขฟังก์ชันค้นหาให้กรองจาก List ที่มีอยู่ ---
  void _filterUsers(String query) {
    if (query.isEmpty) {
      // ถ้าช่องค้นหาว่าง ให้แสดงรายชื่อทั้งหมด
      setState(() {
        _searchResults = _allUsers;
      });
      return;
    }

    // กรองรายชื่อจาก _allUsers ที่มีอยู่แล้ว
    final List<Map<String, dynamic>> filteredUsers = _allUsers.where((user) {
      final phoneNumber = user['phone_number'] as String? ?? '';
      return phoneNumber.contains(query);
    }).toList();

    setState(() {
      _searchResults = filteredUsers;
    });
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
        title: const Text("ค้นหาผู้รับ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (_myPhotoUrl != null && _myPhotoUrl!.isNotEmpty) ? NetworkImage(_myPhotoUrl!) : null,
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
              onChanged: _filterUsers, // <-- MODIFIED: เรียกใช้ฟังก์ชันกรอง
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterUsers(''); // <-- MODIFIED: เรียกฟังก์ชันกรองด้วยค่าว่าง
                  },
                ),
                filled: true,
                fillColor: Colors.grey[200],
                hintText: "กรอกเบอร์โทรศัพท์ผู้รับเพื่อค้นหา",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: _isLoading // <-- MODIFIED: เช็ค isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(child: Text('ไม่พบผู้ใช้', style: TextStyle(color: Colors.grey, fontSize: 16)))
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

  Widget _buildContactTile(BuildContext context, {required Map<String, dynamic> user}) {
    final String name = user['name'] ?? 'ไม่มีชื่อ';
    final String phone = user['phone_number'] ?? 'ไม่มีเบอร์';
    final String address = user['address'] ?? 'ไม่ระบุที่อยู่';
    final String? imageUrl = user['profile_image'] as String?;
    final String userId = user['user_id'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade300,
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? ClipOval(
                  child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                  ),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: ElevatedButton(
          onPressed: () {
            final recipientData = {
              'user_id': userId,
              'name': name,
              'phone': phone,
              'address': address,
              'imageUrl': imageUrl ?? '',
              'addresses': user['addresses'],
            };
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SendItemPage(recipientData: recipientData),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryYellow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: const Text("เลือก", style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}