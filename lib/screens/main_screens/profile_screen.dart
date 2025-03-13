import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:booky/screens/authentication_screens/sign_in_screen.dart';
import 'package:booky/utils/app_state.dart';
import 'package:booky/constants.dart';
import 'package:http/http.dart' as http;
import 'package:booky/utils/api_strings.dart';
import 'package:booky/screens/main_screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = '';
  String? avatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString(AppConstants.spEmailKey);
      String token = prefs.getString(AppConstants.spTokenKey) ?? '';

      print('Debug - Checking saved data:');
      print('Email: $savedEmail');
      print('Token: $token');

      if (savedEmail == null || savedEmail.isEmpty) {
        print('Error: No email found in SharedPreferences');
        return;
      }

      final response = await http.get(
        Uri.parse(
            '${ApiStrings.hostNameUrl}${ApiStrings.getUserInfoUrl}/$savedEmail'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response - Status: ${response.statusCode}');
      print('API Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        print('Response data structure: $responseData');

        if (mounted) {
          setState(() {
            fullName = responseData['fullName'] ?? 'User';
            avatarUrl = responseData['avatarUrl'];
            print('Updated state - Name: $fullName, Avatar: $avatarUrl');
          });
        }

        await prefs.setString(AppConstants.spFullNameKey, fullName);
        await prefs.setString(AppConstants.spAvatarKey, avatarUrl ?? '');
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('getUserInfo error: $e');
    }
  }

  Future<void> updateAvatarOnServer(String base64Image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(AppConstants.spTokenKey) ?? '';
      String? userEmail = prefs.getString(AppConstants.spEmailKey);

      if (userEmail == null) {
        throw Exception('User email not found');
      }

      print('Sending request to update avatar...');

      final response = await http.post(
        Uri.parse('${ApiStrings.hostNameUrl}${ApiStrings.updateAvatarUrl}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': userEmail,
          'avatar': base64Image,
        }),
      );

      print('Update avatar response status: ${response.statusCode}');
      print('Update avatar response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String? newAvatarUrl = responseData['avatarUrl'];

        if (newAvatarUrl != null && newAvatarUrl.isNotEmpty) {
          await prefs.setString(AppConstants.spAvatarKey, newAvatarUrl);
          setState(() {
            avatarUrl = newAvatarUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
            );
          }
        }
      } else {
        throw Exception('Failed to update avatar: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật ảnh đại diện'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        // Xác định định dạng file
        String mimeType = 'jpeg'; // Mặc định
        if (image.path.toLowerCase().endsWith('.png')) {
          mimeType = 'png';
        } else if (image.path.toLowerCase().endsWith('.gif')) {
          mimeType = 'gif';
        } else if (image.path.toLowerCase().endsWith('.webp')) {
          mimeType = 'webp';
        }

        final File originalFile = File(image.path);
        final bytes = await originalFile.readAsBytes();
        final base64Image =
            'data:image/$mimeType;base64,${base64Encode(bytes)}';

        await updateAvatarOnServer(base64Image);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chọn ảnh. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh mới'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? photo = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                      maxWidth: 512,
                      maxHeight: 512,
                    );
                    if (photo != null) {
                      await updateAvatarOnServer(photo.path);
                    }
                  } catch (e) {
                    print('Error taking photo: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể chụp ảnh. Vui lòng thử lại.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa tất cả dữ liệu khi đăng xuất

    AppStateManger.setAppState(1);
    Navigator.of(context).pushReplacementNamed(SignInScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? MemoryImage(base64Decode(avatarUrl!.split(',')[1]))
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? const Icon(
                          Icons.person_outline_rounded,
                          size: 60,
                          color: Colors.grey,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _showImagePickerOptions,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(),
            ),
            CustomListTile(
              label: 'Hồ sơ cá nhân',
              leadingIcon: Icons.person_outline_rounded,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                if (result == true) {
                  // Nếu có cập nhật thông tin, reload profile
                  getUserInfo();
                }
              },
            ),
            CustomListTile(
              label: 'Trung tâm trợ giúp',
              leadingIcon: Icons.help_outline_rounded,
            ),
            CustomListTile(
              label: 'Ví voucher',
              leadingIcon: Icons.wallet_giftcard_outlined,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(),
            ),
            const Spacer(),
            ListTile(
              onTap: logout,
              leading: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  CustomListTile({
    super.key,
    required this.label,
    required this.leadingIcon,
    this.onTap,
  });

  final String label;
  final IconData? leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(leadingIcon),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded),
    );
  }
}
