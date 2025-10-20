// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/profilescreens/settingscreen.dart';
import 'package:chat_app/state/authstate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  bool isSearching = false;
  bool isclicked = false;
  String? selectedValue;
  bool showdropdown = false;
  File? _image;

  DateTime selectedDate = DateTime.now();
  TextEditingController dateController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load user data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final authState = Provider.of<Authstate>(context, listen: false);
    if (authState.usermodel == null) {
      await authState.loaduserdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<Authstate>(context);
    final user = authState.usermodel;
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xff292929),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: size.height * .14,
            decoration: BoxDecoration(
              color: Color(0xff135CAF),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(size.width * 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 40, right: 20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/Logo.png',
                    width: size.width * .25,
                  ),
                  Text(
                    "E-Chat",
                    style: Apptexts.titlestyle.copyWith(color: Colors.white),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Settingscreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.settings, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: size.height * .03),
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xff8495a8),
                backgroundImage:
                    (_image != null)
                        ? FileImage(_image!) as ImageProvider
                        : (user!.profilePicture != null &&
                            user.profilePicture!.isNotEmpty)
                        ? NetworkImage(user.profilePicture!)
                        : null,
                child:
                    (_image == null &&
                            (user!.profilePicture == null ||
                                user.profilePicture!.isEmpty))
                        ? const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white,
                        )
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xff0f79d1),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * .02),
          Text(
            user!.name ?? "No Name",
            style: Apptexts.titlestyle.copyWith(color: Colors.white),
          ),
          SizedBox(height: size.height * .04),
          profileRow("Phone :", user.phoneNumber ?? "Not set"),
          profileRow("Gender :", user.gender ?? "Not set"),
          profileRow("Date of Birth :", user.dob ?? "Not set"),
          profileRow("Email :", user.email ?? "Not set"),
          SizedBox(height: size.height * .03),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () async {
                showeditprofile(context);
              },
              icon: Icon(Icons.edit, color: Colors.white, size: 24),
              label: Text(
                "Edit Profile",
                style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff40C4FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          SizedBox(height: size.height * .02),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                authState.logout();
                Navigator.of(context).pushReplacementNamed('/Onboardinscreen');
              },
              icon: Icon(Icons.logout, color: Color(0xffF6695E), size: 24),
              label: const Text(
                "Logout",
                style: TextStyle(color: Color(0xffF6695E)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget profileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
            },
            child: Icon(Icons.copy, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  void showeditprofile(BuildContext context) {
    final authState = Provider.of<Authstate>(context, listen: false);
    final user = authState.usermodel;

    nameController.text = user?.name ?? "";
    phoneController.text = user?.phoneNumber ?? "";
    emailController.text = user?.email ?? "";

    Size size = MediaQuery.of(context).size;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder:
              (_, controller) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xff4a4b62),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 4,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Edit Profile",
                          style: Apptexts.titlestyle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * .03),
                      Text(
                        "Name",
                        style: Apptexts.subtitlestyle.copyWith(
                          color: Color(0xffD0D1DB),
                        ),
                      ),
                      SizedBox(height: size.height * .01),
                      TextField(
                        controller: nameController,
                        style: Apptexts.subtitlestyle.copyWith(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * .02),
                      Text(
                        "Phone Number",
                        style: Apptexts.subtitlestyle.copyWith(
                          color: Color(0xffD0D1DB),
                        ),
                      ),
                      SizedBox(height: size.height * .01),
                      TextField(
                        controller: phoneController,
                        readOnly: true,
                        style: Apptexts.bodystyle.copyWith(color: Colors.grey),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * .02),
                      Text(
                        "Gender",
                        style: Apptexts.subtitlestyle.copyWith(
                          color: Color(0xffD0D1DB),
                        ),
                      ),
                      SizedBox(height: size.height * .01),
                      DropdownButtonFormField<String>(
                        value:
                            genderController.text.isEmpty
                                ? null
                                : genderController.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        hint: Text(
                          "Select Gender",
                          style: Apptexts.bodystyle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        dropdownColor: Colors.grey[800],
                        style: Apptexts.subtitlestyle.copyWith(
                          color: Colors.white,
                        ),
                        items:
                            ['Male', 'Female', 'Other']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            genderController.text = value!;
                          });
                        },
                      ),

                      SizedBox(height: size.height * .02),

                      Text(
                        "Date of Birth",
                        style: Apptexts.subtitlestyle.copyWith(
                          color: Color(0xffD0D1DB),
                        ),
                      ),
                      SizedBox(height: size.height * .01),
                      TextField(
                        controller: dateController,
                        style: Apptexts.bodystyle.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "DD/MM/YYYY",
                          hintStyle: Apptexts.bodystyle.copyWith(
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          label: Text(
                            "Date of Birth",
                            style: Apptexts.bodystyle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                dateController.text =
                                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * .02),

                      Text(
                        "Email",
                        style: Apptexts.subtitlestyle.copyWith(
                          color: Color(0xffD0D1DB),
                        ),
                      ),
                      SizedBox(height: size.height * .01),
                      TextField(
                        controller: emailController,
                        readOnly: true,
                        style: Apptexts.bodystyle.copyWith(color: Colors.grey),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * .03),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: Color(0xff3AB2E8)),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff3AB2E8),
                              ),
                              onPressed: () async {
                                await authState.updateProfile(
                                  name: nameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  gender: genderController.text.trim(),
                                  dob: dateController.text.trim(),
                                );
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Update",
                                style: Apptexts.subtitlestyle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    if (kIsWeb) {
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
        saveProfile();
      }
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        _image = File(image.path);
                      });
                      saveProfile();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      setState(() {
                        _image = File(image.path);
                      });
                      saveProfile();
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/darlhfapb/upload");
      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = 'imageupload'
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final jsonMap = json.decode(resStr);
        return jsonMap['secure_url'];
      } else {
        print('Failed to upload image: ${response.statusCode}');
        SnackbarMessage.failedsnack("Failed to upload image", context);
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      SnackbarMessage.failedsnack("Error uploading image", context);
      return null;
    }
  }

  void saveProfile() async {
    final authState = Provider.of<Authstate>(context, listen: false);

    // FIX: Check if user is authenticated
    if (authState.usermodel == null) {
      SnackbarMessage.failedsnack("User not authenticated", context);
      return;
    }

    String? imageUrl = authState.usermodel?.profilePicture;

    if (_image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      try {
        final uploadedUrl = await uploadImageToCloudinary(_image!);
        Navigator.pop(context);

        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          print("Image URL: $imageUrl");

          await authState.updateProfile(imageUrl: imageUrl);

          SnackbarMessage.successsnack(
            "Profile image updated successfully",
            context,
          );
        } else {
          SnackbarMessage.failedsnack("Failed to upload image", context);
        }
      } catch (e) {
        Navigator.pop(context);
        SnackbarMessage.failedsnack("Error updating profile: $e", context);
      }
    } else {
      try {
        await authState.updateProfile();
        SnackbarMessage.successsnack("Profile updated successfully", context);
      } catch (e) {
        SnackbarMessage.failedsnack("Error updating profile: $e", context);
      }
    }
  }
}
