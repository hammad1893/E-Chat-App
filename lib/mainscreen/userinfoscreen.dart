import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chat_app/bottomnavigation.dart';
import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/state/authstate.dart';
import 'package:chat_app/widget/elevatedbutton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

class Userinfoscreen extends StatefulWidget {
  const Userinfoscreen({super.key});

  @override
  State<Userinfoscreen> createState() => _UserinfoscreenState();
}

class _UserinfoscreenState extends State<Userinfoscreen> {
  File? _image;
  TextEditingController phoneController = TextEditingController();
  Uint8List? _webImage;

  Future<void> pickImage() async {
    if (kIsWeb) {
      // 📌 Web
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedImage != null) {
        final imageBytes = await pickedImage.readAsBytes();
        setState(() {
          _webImage = imageBytes;
        });
      }
    } else {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
        });
      }
    }
  }

  Future<String?> uploadImageToCloudinary({
    File? imageFile,
    Uint8List? webImage,
  }) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/darlhfapb/upload");
      var request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'imageupload';

      if (kIsWeb && webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImage,
            filename: "upload.png",
          ),
        );
      } else if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final jsonMap = json.decode(resStr);
        return jsonMap['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  void saveProfile() async {
    final authState = Provider.of<Authstate>(context, listen: false);
    String? imageUrl = authState.usermodel?.profilePicture;

    if (_image != null || _webImage != null) {
      final uploadedUrl = await uploadImageToCloudinary(
        imageFile: _image,
        webImage: _webImage,
      );
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      } else {
        SnackbarMessage.failedsnack("Failed to upload image", context);
        return;
      }
    }

    try {
      await authState.updateProfile(
        phone: normalizePhone(phoneController.text),
        imageUrl: imageUrl,
      );

      AppUtils.success(context, "✅ Profile Created successfully");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomBottomNavBar()),
      );
    } catch (e) {
      SnackbarMessage.failedsnack(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xff292929),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: size.height * .32,
              color: Color(0xff092a51),
              child: Column(
                children: [
                  SizedBox(height: size.height * .12),
                  GestureDetector(
                    onTap: pickImage, // when avatar tapped → open gallery
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color(0xff8495a8),
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: Stack(
                        children: [
                          if (_image ==
                              null) // show person icon only when no image
                            const Center(
                              child: Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          Align(
                            alignment: Alignment.topRight,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xff0f79d1),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: size.height * .09,
              color: Color(0xff2c2d3a),
            ),
            SizedBox(height: size.height * .04),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Phone Number",
                    style: Apptexts.titlestyle.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * .01),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: IntlPhoneField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: "Enter Phone Number",
                  hintStyle: TextStyle(color: Color(0xffF0F0F3)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xff9A9BB1), width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xff9A9BB1),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xff9A9BB1),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownTextStyle: const TextStyle(color: Colors.white),
                initialCountryCode: 'PK',
                onChanged: (phone) {
                  print(phone.completeNumber);
                },
              ),
            ),
            SizedBox(height: size.height * .03),
            CustomElevatedButton(
              text: "Save",
              onPress: () {
                saveProfile();
              },
            ),
          ],
        ),
      ),
    );
  }
}
