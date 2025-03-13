import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_strings.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class AddEditCategory extends StatefulWidget {
  final Map<String, dynamic>? category;

  AddEditCategory({this.category});

  @override
  _AddEditCategoryState createState() => _AddEditCategoryState();
}

class _AddEditCategoryState extends State<AddEditCategory> {
  final nameController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      nameController.text = widget.category!['name'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiStrings.hostNameUrl}/api/categories/upload-image'),
      );

      var imageStream = http.ByteStream(image.openRead());
      var length = await image.length();

      var multipartFile = http.MultipartFile(
        'category_image',
        imageStream,
        length,
        filename: image.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print('Upload response: $responseData');

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData);
        String imageUrl = jsonData['imageUrl'];
        return imageUrl;
      }
      throw Exception('Upload failed with status code: ${response.statusCode}');
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveCategory() async {
    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
        print('Image URL after upload: $imageUrl');
      }

      final url = widget.category == null
          ? '${ApiStrings.hostNameUrl}/api/categories'
          : '${ApiStrings.hostNameUrl}/api/categories/${widget.category!['category_id']}';

      final response = widget.category == null
          ? await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'name': nameController.text,
                'category_image': imageUrl ?? ''
              }),
            )
          : await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'name': nameController.text,
                'category_image': imageUrl ?? ''
              }),
            );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to save category');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Thêm Thể loại' : 'Sửa Thể loại'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Tên thể loại'),
            ),
            Text('Hình ảnh thể loại'),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                margin: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50),
                          Text('Chọn hình ảnh'),
                        ],
                      ),
              ),
            ),
            ElevatedButton(
              onPressed: _saveCategory,
              child: Text(widget.category == null ? 'Thêm' : 'Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}
