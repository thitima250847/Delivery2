import 'dart:typed_data';
import 'package:delivery/user/history.dart';
import 'package:delivery/user/home_user.dart';
import 'package:delivery/user/more.dart';
import 'package:delivery/user/receive.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http_parser/http_parser.dart'; 
// import 'package:delivery/config/config_Img.dart'; // ไม่จำเป็นต้องใช้ import นี้แล้ว

// *** FIX: ใช้ Class Config ที่กำหนด URL ของ Render แล้ว ***
class Config {
  // URL ของ Custom Server ที่รันอยู่บน Render
  static const String baseUrl = 'https://node-storage-192w.onrender.com'; 
}

class SendItemPage extends StatefulWidget {
  const SendItemPage({super.key});

  @override
  State<SendItemPage> createState() => _SendItemPageState();
}

class _SendItemPageState extends State<SendItemPage> {
  static const Color primaryColor = Color(0xFFFEE146);
  static const Color greenColor = Colors.green;
  final ImagePicker _picker = ImagePicker();

  // สถานะสำหรับเก็บข้อมูลสินค้าที่จะส่ง (แค่ 1 รายการ)
  Uint8List? _currentImageBytes;
  String? _currentImageExtension;
  final TextEditingController _descriptionController = TextEditingController();

  // สถานะ UI
  bool _isSaving = false;

  // ------------------------------------------------------------------
  // --- Utility & Image Picker Logic ---
  // ------------------------------------------------------------------

  // FIX: เพิ่ม Named Parameter isSuccess เพื่อกำหนดสี SnackBar
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
      final xFile = await _picker.pickImage(
          source: source, imageQuality: 75);
      if (xFile == null) return;

      final fileExtension = xFile.path.split('.').last.toLowerCase();
      if (fileExtension != 'jpg' && fileExtension != 'jpeg' && fileExtension != 'png') {
        _showSnack('ไม่รองรับไฟล์ประเภทนี้ (รองรับเฉพาะ jpg, jpeg, png)');
        return;
  	  }

      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
  	  setState(() {
        _currentImageBytes = bytes;
        _currentImageExtension = fileExtension;
  	  });
  	} catch (e) {
    	_showSnack('เลือกรูปไม่สำเร็จ: $e');
  	}
  }
  
  // --- Custom Server Uploader Logic ---
  Future<String?> _uploadImageToCustomServer(
    String packageId, 
    Uint8List imageBytes,
    String fileExtension,
  ) async {
  	// URL ถูกกำหนดค่าเป็น URL ของ Render แล้ว
  	final uri = Uri.parse('${Config.baseUrl}/upload');
  	final request = http.MultipartRequest('POST', uri);

  	final contentType = fileExtension == 'png' ? 'png' : 'jpeg';
  	final filename = '$packageId\_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
  	
  	final file = http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: filename,
      contentType: MediaType('image', contentType),
  	);

  	request.files.add(file);

  	try {
    		final streamedResponse = await request.send();
  			final response = await http.Response.fromStream(streamedResponse);

  		if (response.statusCode == 200 || response.statusCode == 201) {
  			final responseData = json.decode(response.body);
  			final receivedFilename = responseData['filename'] ?? filename; 
  			
  			final imageUrl = '${Config.baseUrl}/upload/$receivedFilename';
  			return imageUrl;
  			
  		} else {
  			// แสดง Error Code ของ Server (เช่น 404, 500)
  			_showSnack('อัปโหลดรูปไม่สำเร็จ: Server error ${response.statusCode}');
  			return null;
  		}
  	} catch (e) {
  			// แสดง Network Error (เช่น Connection refused)
  	  	_showSnack('อัปโหลดรูปไม่สำเร็จ (Network Error): $e');
  			return null;
  	}
  }

  // ------------------------------------------------------------------
  // --- Core Save Logic ---
  // ------------------------------------------------------------------

  Future<void> _saveAllData() async {
  	final description = _descriptionController.text.trim();

  	if (_currentImageBytes == null || description.isEmpty) {
  		_showSnack('กรุณาเลือกรูปภาพและระบุรายละเอียดสินค้าให้ครบถ้วน');
  		return;
  	}

  	setState(() {
  		_isSaving = true;
  	});

  	final packageId = 'pkg_${DateTime.now().millisecondsSinceEpoch}';
  	String? imageUrl;
  	
  	// 2. อัปโหลดรูปภาพไปยัง Custom Server 
  	imageUrl = await _uploadImageToCustomServer(
        packageId, _currentImageBytes!, _currentImageExtension!);

  	if (imageUrl == null) {
  		setState(() { _isSaving = false; });
  		return; 
  	}

  	// 3. เตรียม Payload
  	final List<Map<String, String>> itemsPayload = [{
        'description': description,
        'proof_image_url': imageUrl, 
  	}];
  	
  	// ข้อมูล Address (Mock-up)
  	final Map<String, dynamic> mockSenderAddress = {
        'address_text': 'หอพักกรุุหตาม', 
        'latitude': 16.4884, 
        'longitude': 102.8336,
  	};
  	final Map<String, dynamic> mockReceiverAddress = {
        'address_text': 'จุดรับสินค้าปลายทาง', 
        'latitude': 16.5000,
        'longitude': 102.8500,
  	};
  	
  	// 4. เรียกใช้ Cloud Function: createPackage
  	try {
  		final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createPackage');
  		
  		final result = await callable.call(<String, dynamic>{
    			'senderAddress': mockSenderAddress,
    			'receiverAddress': mockReceiverAddress, 
    			'items': itemsPayload,
  			'pkgDescription': description, 
  		});

  		final createdPackage = result.data['package'];
  		_showSnack('สร้างรายการส่งสินค้า ${createdPackage['id']} สำเร็จ! กำลังไปยังหน้าผู้รับ', isSuccess: true); 

  		// 5. ไปยังหน้าถัดไป
  		if (!mounted) return;
  		Navigator.push(
      			context,
      			MaterialPageRoute(builder: (context) => const ReceivePage()),
  		);

  	} on FirebaseFunctionsException catch (e) {
  		_showSnack('สร้างรายการส่งสินค้าไม่สำเร็จ (Cloud Function Error): ${e.message}');
  	} catch (e) {
  		_showSnack('เกิดข้อผิดพลาดที่ไม่คาดคิดในการบันทึก: $e');
  	} finally {
  		if (mounted) {
  			setState(() {
  				_isSaving = false;
  				_currentImageBytes = null;
  				_currentImageExtension = null;
  				_descriptionController.clear();
  			});
  		}
  	}
  }

  // --- ฟังก์ชันสำหรับสร้างปุ่ม อัปโหลด/ถ่ายรูป (Updated) ---
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

  // --- ฟังก์ชันใหม่: สร้างปุ่มบันทึก (Updated for Firebase Logic) ---
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
  					child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
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

  // --- UI Structure (เหมือนเดิม) ---
  @override
  Widget build(BuildContext context) {
  	const Color primaryColor = Color(0xFFFEE146);

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

  					// --- ปุ่มอัปโหลด/ถ่ายรูป ---
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

  					// --- TextField รายละเอียดสินค้า ---
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
  							enabledBorder: OutlineInputBorder(
  								borderRadius: BorderRadius.circular(15),
  								borderSide: BorderSide(color: Colors.grey.shade300),
  							),
  							focusedBorder: OutlineInputBorder(
  								borderRadius: BorderRadius.circular(15),
  								borderSide: const BorderSide(color: primaryColor, width: 2),
  							),
  						),
  					),
  					const SizedBox(height: 32),

  					// --- ปุ่ม "บันทึกข้อมูลทั้งหมด" ---
  					Align(
  						alignment: Alignment.center,
  						child: _buildSaveButton(context),
  					),
  					const SizedBox(height: 24),
  				],
  			),
  		),
  		// --- Bottom Navigation Bar ---
  		bottomNavigationBar: _buildBottomNavigationBar(context),
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
    				const CircleAvatar(
    					radius: 35,
    					backgroundColor: Colors.grey,
    				),
    				const SizedBox(width: 16),
    				Expanded(
    					child: Column(
    						crossAxisAlignment: CrossAxisAlignment.start,
    						children: [
    							_buildInfoRow('ชื่อ', 'ตัวดี'),
    							const SizedBox(height: 4),
    							_buildInfoRow('หมายเลขโทรศัพท์', '0987490007'),
  	                        const SizedBox(height: 4),
  	                        _buildInfoRow('ที่อยู่', 'หอพักกรุุหตาม'),
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
  	const Color primaryColor = Color(0xFFFEE146);
  	return BottomNavigationBar(
    		backgroundColor: Colors.white,
    		selectedItemColor: primaryColor,
    		unselectedItemColor: const Color.fromARGB(255, 20, 19, 19),
    		currentIndex: 0, 
    		onTap: (index) {
    			switch (index) {
    				case 0:
    					break;
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
