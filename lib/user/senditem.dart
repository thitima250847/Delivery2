import 'dart:typed_data';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/receive.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';

// --- แก้ไข: ลบ class Config และ import ที่เกี่ยวกับ http ออก ---

class SendItemPage extends StatefulWidget {
  final Map<String, String> recipientData;
  const SendItemPage({super.key, required this.recipientData});

  @override
  State<SendItemPage> createState() => _SendItemPageState();
}

class _SendItemPageState extends State<SendItemPage> {
  static const Color primaryColor = Color(0xFFFEE146);
  final ImagePicker _picker = ImagePicker();

  Uint8List? _currentImageBytes;
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSaving = false;

  String _recipientName = 'ผู้รับ';
  String _recipientPhone = 'ไม่ระบุ';
  String _recipientAddress = 'ไม่ระบุ';
  String? _recipientImageUrl;

  @override
  void initState() {
    super.initState();
    _recipientName = widget.recipientData['name'] ?? _recipientName;
    _recipientPhone = widget.recipientData['phone'] ?? _recipientPhone;
    _recipientAddress = widget.recipientData['address'] ?? _recipientAddress;
    _recipientImageUrl = widget.recipientData['imageUrl'];
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
      setState(() {
        _currentImageBytes = bytes;
      });
    } catch (e) {
      _showSnack('เลือกรูปไม่สำเร็จ: $e');
    }
  }

  // --- แก้ไข: ลบฟังก์ชัน _uploadImageToCustomServer ออกทั้งหมด ---

  Future<void> _saveAllData() async {
    final description = _descriptionController.text.trim();

    if (_currentImageBytes == null || description.isEmpty) {
      _showSnack('กรุณาเลือกรูปภาพและระบุรายละเอียดสินค้าให้ครบถ้วน');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // หมายเหตุ: ส่วนนี้ยังคงใช้ Mock Data อยู่ หากต้องการใช้ข้อมูลจริง
    // คุณจะต้องดึงข้อมูลที่อยู่ของผู้ส่งและผู้รับมาใช้งานแทน mockSenderAddress และ mockReceiverAddress
    final Map<String, dynamic> mockSenderAddress = {
      'address_text': 'หอพักต้นทาง',
      'latitude': 16.4884,
      'longitude': 102.8336,
    };
    final Map<String, dynamic> mockReceiverAddress = {
      'address_text': _recipientAddress, // ใช้ที่อยู่ผู้รับจริง
      'latitude': 16.5000, // ควรใช้ lat,lng จริงของผู้รับ
      'longitude': 102.8500, // ควรใช้ lat,lng จริงของผู้รับ
    };

    try {
      // หมายเหตุ: ส่วนนี้ยังไม่ได้ทำการอัปโหลดรูปภาพสินค้าไปที่ไหน
      // ในอนาคตคุณต้องเพิ่ม Logic การอัปโหลดรูปสินค้า (เช่น ไปที่ Cloudinary หรือ Firebase Storage)
      // แล้วนำ URL ที่ได้มาใส่ใน itemsPayload
      final List<Map<String, String>> itemsPayload = [
        {'description': description, 'proof_image_url': 'YOUR_ITEM_IMAGE_URL_HERE'},
      ];


      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createPackage');

      final result = await callable.call(<String, dynamic>{
        'senderAddress': mockSenderAddress,
        'receiverAddress': mockReceiverAddress,
        'items': itemsPayload,
        'pkgDescription': description,
      });

      _showSnack('สร้างรายการส่งสินค้าสำเร็จ!', isSuccess: true);

      if (!mounted) return;
      // ควรจะไปยังหน้าสถานะ หรือหน้าประวัติ มากกว่ากลับไปหน้า Receive
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );

    } on FirebaseFunctionsException catch (e) {
      _showSnack('สร้างรายการส่งสินค้าไม่สำเร็จ: ${e.message}');
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
              'บันทึก และ ไปหน้าผู้รับ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
    );
  }

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.15),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserInfoCard(),
            const SizedBox(height: 24),
            Center(
              child: Container(
                height: 150,
                width: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _currentImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          _currentImageBytes!,
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
  
  // --- ไม่ต้องแก้ไขส่วนนี้ โค้ดถูกต้องแล้ว ---
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
            child: (_recipientImageUrl != null && _recipientImageUrl!.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      _recipientImageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.white, size: 35);
                      },
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
        if (index == 0) return; // Prevent navigating to the same page
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