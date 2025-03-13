import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_strings.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddEditBookScreen extends StatefulWidget {
  final Map<String, dynamic>? book;

  AddEditBookScreen({this.book});

  @override
  _AddEditBookScreenState createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final categoryIdController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<File> _previewImages = [];
  List<dynamic> categories = [];
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    if (widget.book != null) {
      titleController.text = widget.book!['title'] ?? '';
      authorController.text = widget.book!['author'] ?? '';
      priceController.text = widget.book!['price']?.toString() ?? '';
      descriptionController.text = widget.book!['description'] ?? '';
      imageUrlController.text = widget.book!['image_url'] ?? '';
      categoryIdController.text = widget.book!['category_id']?.toString() ?? '';
    }
  }

  Future<void> fetchCategories() async {
    final response =
        await http.get(Uri.parse('${ApiStrings.hostNameUrl}/api/categories'));
    if (response.statusCode == 200) {
      setState(() {
        categories = jsonDecode(response.body)['data'];
      });
    } else {
      // Handle error
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    if (image == null) return null;

    try {
      print('Starting image upload...');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiStrings.hostNameUrl}/api/books/upload'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
      ));

      print('Sending request to server...');
      var response = await request.send();
      print('Response status code: ${response.statusCode}');

      var responseData = await response.stream.bytesToString();
      print('Response data: $responseData');

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData);
        return jsonData['imageUrl'];
      }
      throw Exception('Upload failed with status code: ${response.statusCode}');
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickPreviewImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _previewImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
      print('Uploaded cover image URL: $imageUrl');
    }

    List<String> previewImageUrls = [];
    for (var image in _previewImages) {
      String? imageUrl = await _uploadImage(image);
      if (imageUrl != null) {
        previewImageUrls.add(imageUrl);
        print('Uploaded preview image URL: $imageUrl');
      }
    }

    print('Book ID to be sent: ${widget.book?['book_id']}');

    print('Selected Category ID: $selectedCategoryId');

    final bookData = {
      'title': titleController.text,
      'author': authorController.text,
      'price': double.parse(priceController.text),
      'quantity': int.parse(quantityController.text),
      'description': descriptionController.text,
      'image_url': imageUrl ?? imageUrlController.text,
      'preview_images': previewImageUrls,
      'book_id': widget.book?['book_id'],
      'category_id': selectedCategoryId,
    };

    print('Book data to be saved: $bookData');

    try {
      final response = widget.book == null
          ? await http.post(
              Uri.parse('${ApiStrings.hostNameUrl}/api/books'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(bookData),
            )
          : await http.put(
              Uri.parse(
                  '${ApiStrings.hostNameUrl}/api/books/${widget.book!['book_id']}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(bookData),
            );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.book == null
                  ? 'Thêm sách thành công'
                  : 'Cập nhật sách thành công')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save book: ${response.body}');
      }
    } catch (e) {
      print('Error saving book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu sách: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'Thêm Sách' : 'Sửa Sách'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Tiêu đề'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập tiêu đề';
                  return null;
                },
              ),
              TextFormField(
                controller: authorController,
                decoration: InputDecoration(labelText: 'Tác giả'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập tác giả';
                  return null;
                },
              ),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá';
                  if (double.tryParse(value!) == null)
                    return 'Giá không hợp lệ';
                  return null;
                },
              ),
              //SỐ LƯỢNG
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số lượng';
                  if (int.tryParse(value!) == null)
                    return 'Số lượng không hợp lệ';
                  return null;
                },
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: InputDecoration(labelText: 'Chọn thể loại'),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['category_id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Vui lòng chọn thể loại';
                  return null;
                },
              ),
              Text('Ảnh bìa'),
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
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50),
                            Text('Chọn ảnh bìa'),
                          ],
                        ),
                ),
              ),
              Text('Ảnh đọc thử'),
              GestureDetector(
                onTap: _pickPreviewImages,
                child: Container(
                  height: 200,
                  margin: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _previewImages.isNotEmpty
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _previewImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.file(_previewImages[index],
                                  fit: BoxFit.cover),
                            );
                          },
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50),
                            Text('Chọn ảnh đọc thử'),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveBook,
                child: Text(widget.book == null ? 'Thêm' : 'Cập nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
