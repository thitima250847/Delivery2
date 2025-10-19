import 'dart:convert';
import 'dart:typed_data';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CloudinaryConfig {
  static const String cloudName = 'dwltvhlju';
  static const String uploadPreset = 'delivery';
}

class SendItemPage extends StatefulWidget {
  final Map<String, dynamic> recipientData;
  const SendItemPage({super.key, required this.recipientData});

  @override
  State<SendItemPage> createState() => _SendItemPageState();
}

class _SendItemPageState extends State<SendItemPage> {
  static const Color primaryColor = Color(0xFFFEE146);
  final ImagePicker _picker = ImagePicker();

  Uint8List? _itemImageBytes;
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;

  String _recipientId = '';
  String _recipientName = 'ผู้รับ';
  String _recipientPhone = 'ไม่ระบุ';
  String _recipientAddress = 'ไม่ระบุ';
  String? _recipientImageUrl;
  Map<String, dynamic>? _senderData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("ไม่พบผู้ใช้ที่ล็อกอินอยู่");

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) throw Exception("ไม่พบข้อมูลผู้ส่งในระบบ");

      _senderData = doc.data();
      _recipientId = widget.recipientData['user_id'] ?? '';
      _recipientName = widget.recipientData['name'] ?? 'ผู้รับ';
      _recipientPhone = widget.recipientData['phone'] ?? 'ไม่ระบุ';
      _recipientAddress = widget.recipientData['address'] ?? 'ไม่ระบุ';
      _recipientImageUrl = widget.recipientData['imageUrl'];

      final addresses = widget.recipientData['addresses'] as List<dynamic>?;
      if (addresses != null && addresses.isNotEmpty) {
      }
    } catch (e) {
      if (mounted) _showSnack("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _pickImage(ImageSource source) async {
    if (_isSaving) return;
    try {
      final xFile = await _picker.pickImage(source: source, imageQuality: 75);
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      setState(() => _itemImageBytes = bytes);
    } catch (e) {
      _showSnack('เลือกรูปไม่สำเร็จ: $e');
    }
  }

  Future<String?> _uploadItemImageToCloudinary(Uint8List imageBytes) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'item_upload.jpg',
        ),
      );
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        return decodedData['secure_url'];
      } else {
        _showSnack('อัปโหลดรูปสินค้าไม่สำเร็จ: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาดในการเชื่อมต่อ Cloudinary: $e');
      return null;
    }
  }

  // senditem.dart

  // ... (โค้ดส่วนอื่น ๆ เหมือนเดิม) ...

  Future<void> _saveAllData() async {
    final description = _descriptionController.text.trim();
    if (_itemImageBytes == null || description.isEmpty) {
      _showSnack('กรุณาเลือกรูปภาพและระบุรายละเอียดสินค้าให้ครบถ้วน');
      return;
    }
    if (_senderData == null || _recipientId.isEmpty) {
      _showSnack('เกิดข้อผิดพลาด: ไม่พบข้อมูลผู้ส่งหรือผู้รับ');
      return;
    }
    setState(() => _isSaving = true);

    try {
      // 1. อัปโหลดรูปสินค้าไป Cloudinary (เหมือนเดิม)
      final String? itemImageUrl = await _uploadItemImageToCloudinary(
        _itemImageBytes!,
      );
      if (itemImageUrl == null) {
        // หากอัปโหลดไม่สำเร็จ ให้หยุดการทำงาน
        setState(() => _isSaving = false);
        return;
      }

      // 2. ดึง user_id ของผู้ส่ง (ผู้ใช้ปัจจุบัน)
      final senderId = FirebaseAuth.instance.currentUser?.uid;
      if (senderId == null) {
        throw Exception("ไม่สามารถระบุตัวตนผู้ส่งได้");
      }

      // 3. (ส่วนที่แก้ไข) สร้างข้อมูลที่จะบันทึกลง Firestore โดยตรง
      final packageData = <String, dynamic>{
        // --- ข้อมูลหลัก ---
        'sender_user_id': senderId, // user_id ของผู้ส่ง
        'receiver_user_id': _recipientId, // user_id ของผู้รับ
        'package_description': description, // ข้อความที่ส่งถึง
        'proof_image_url': itemImageUrl, // รูปสินค้าจาก Cloudinary
        'created_at': Timestamp.now(), // วันที่และเวลาที่สร้างรายการ
        'status': 'pending', // สถานะเริ่มต้น (แนะนำให้มี)
        // --- ข้อมูลผู้รับ (Snapshot ณ เวลาที่ส่ง) ---
        'receiver_info': {
          'name': _recipientName,
          'phone': _recipientPhone,
          'address': _recipientAddress,
        },
        // --- ข้อมูลผู้ส่ง (Snapshot ณ เวลาที่ส่ง) ---
        'sender_info': {
          'name': _senderData?['name'] ?? 'ไม่ระบุ',
          'phone': _senderData?['phone_number'] ?? 'ไม่ระบุ',
          // --- เพิ่มที่อยู่ของผู้ส่ง ---
          'address':
              ((_senderData?['addresses'] as List<dynamic>?)?.isNotEmpty ??
                  false)
              ? (_senderData!['addresses'][0]
                        as Map<String, dynamic>)['address_text'] ??
                    'ไม่ระบุ'
              : 'ไม่ระบุ',
        },
      };

      // 4. (ส่วนที่แก้ไข) บันทึกข้อมูลลงใน collection 'packages'
      await FirebaseFirestore.instance.collection('packages').add(packageData);

      _showSnack('สร้างรายการส่งสินค้าสำเร็จ!', isSuccess: true);
      if (!mounted) return;
      // ไปยังหน้าประวัติการส่ง
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
        (route) => false,
      );
    } catch (e) {
      // ปรับปรุงการแสดงข้อผิดพลาดให้ครอบคลุมมากขึ้น
      _showSnack('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ... (โค้ดส่วนอื่น ๆ เหมือนเดิม) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ส่งสินค้า',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        height: 150,
                        width: 150,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: _itemImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.memory(
                                  _itemImageBytes!,
                                  fit: BoxFit.cover,
                                  width: 150,
                                  height: 150,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
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
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                      _buildImageActionButton(
                        label: 'ถ่ายรูปสินค้า',
                        icon: Icons.camera_alt_outlined,
                        color: primaryColor,
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _descriptionController,
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
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.center,
                    child: _buildSaveButton(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildImageActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveAllData,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'บันทึก',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
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
            child:
                (_recipientImageUrl != null && _recipientImageUrl!.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      _recipientImageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 35),
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

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) return;
        switch (index) {
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
