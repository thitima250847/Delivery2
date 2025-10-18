import 'package:delivery/user/senditem.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:delivery/config/config_Img.dart';

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

  String? _myPhotoUrl; // รูปโปรไฟล์ของผู้ใช้ปัจจุบัน

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

  // เติม baseUrl ถ้าค่าเป็น path
  String _resolveImageUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    return '${Config.baseUrl}/${raw.replaceFirst(RegExp(r'^/'), '')}';
  }

  Future<void> _loadMyAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (mounted) {
        setState(() {
          final val = (data?['profile_image'] as String?)?.trim();
          _myPhotoUrl =
              (val != null && val.isNotEmpty) ? _resolveImageUrl(val) : null;
        });
      }
    } catch (_) {
      // เงียบไว้ ถ้าโหลดรูปไม่ได้จะโชว์ไอคอนเริ่มต้นแทน
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

            // เตรียมรูปให้เป็น URL ที่ใช้งานได้
            final rawImg = (data['profile_image'] as String?)?.trim();
            if (rawImg != null && rawImg.isNotEmpty) {
              data['profile_image'] = _resolveImageUrl(rawImg);
            } else {
              data['profile_image'] = '';
            }

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
              backgroundImage:
                  _myPhotoUrl != null ? NetworkImage(_myPhotoUrl!) : null,
              child: _myPhotoUrl == null
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
    final String? imageUrl = (user['profile_image'] as String?);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade300,
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    // บังคับให้เป็น URL ที่ใช้ได้เสมอ (รองรับกรณีเป็น path)
                    imageUrl.startsWith('http')
                        ? imageUrl
                        : '${Config.baseUrl}/${imageUrl.replaceFirst(RegExp(r'^/'), '')}',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    // ถ้าโหลดรูปไม่ได้ ให้แสดงไอคอนคนแทน
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
