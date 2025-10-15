// import 'package:chat_app/constants/text.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class Groupinfoscreen extends StatefulWidget {
//   final String? groupId;

//   const Groupinfoscreen({super.key, this.groupId});

//   @override
//   State<Groupinfoscreen> createState() => _GroupinfoscreenState();
// }

// class _GroupinfoscreenState extends State<Groupinfoscreen> {
//   bool muteNotification = false;
//   bool protectedChat = false;
//   bool hideChat = false;
//   bool hideChatHistory = false;

//   @override
//   void initState() {
//     super.initState();
//     groupprovider=Provider.of(context,listen: false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: const Color(0xff292929),
//       appBar: AppBar(
//         backgroundColor: const Color(0xff292929),
//         elevation: 0,
//         leading: Container(
//           margin: const EdgeInsets.all(8),
//           decoration: const BoxDecoration(
//             color: Color(0xff3e3e3e),
//             shape: BoxShape.circle,
//           ),
//           child: IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//           ),
//         ),
//         actions: [
//           Container(
//             margin: const EdgeInsets.all(8),
//             decoration: const BoxDecoration(
//               color: Color(0xff3e3e3e),
//               shape: BoxShape.circle,
//             ),
//             child: Image.asset(
//               "assets/images/video.png",
//               height: size.height * .06,
//               width: size.width * .12,
//               color: Colors.white,
//             ),
//           ),
//           Container(
//             margin: const EdgeInsets.all(8),
//             decoration: const BoxDecoration(
//               color: Color(0xff3e3e3e),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               onPressed: () {},
//               icon: const Icon(Icons.call_outlined, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: Column(
//           children: [
//             // Profile Image
//             CircleAvatar(
//               radius: 50,
//               backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=12"),
//             ),
//             SizedBox(height: size.height * .03),

//             // Name
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "David Wayne",
//                   style: Apptexts.titlestyle.copyWith(color: Colors.white),
//                 ),
//                 SizedBox(width: size.width * .02),
//                 Icon(Icons.edit, size: 16, color: Color(0xffF0F0F3)),
//               ],
//             ),

//             SizedBox(height: size.height * .01),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   "19 members",
//                   style: TextStyle(color: Color(0xffF0F0F3), fontSize: 14),
//                 ),
//               ],
//             ),
//             SizedBox(height: size.height * .03),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xff40C4FF),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: Text(
//                   "View Members",
//                   style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
//                 ),
//               ),
//             ),
//             SizedBox(height: size.height * .03),
//             Divider(color: Colors.white24),
//             GestureDetector(
//               onTap: () {
//                 // Navigator.push(
//                 //   context,
//                 //   MaterialPageRoute(builder: (context) => ChatDetailsPage()),
//                 // );
//               },
//               child: _buildOption(
//                 image: "assets/images/media.png",
//                 title: "Media, Links & Documents",
//                 trailing: const Text(
//                   "152",
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 showArrow: true,
//               ),
//             ),
//             _buildSwitchOption(
//               image: "assets/images/volum.png",
//               title: "Mute Notification",
//               value: muteNotification,
//               onChanged: (v) => setState(() => muteNotification = v),
//             ),
//             _buildOption(
//               image: "assets/images/bell.png",
//               title: "Custom Notification",
//               showArrow: true,
//             ),
//             _buildSwitchOption(
//               image: "assets/images/protect.png",
//               title: "Protected Chat",
//               value: protectedChat,
//               onChanged: (v) => setState(() => protectedChat = v),
//             ),
//             _buildSwitchOption(
//               image: "assets/images/eye.png",
//               title: "Hide Chat",
//               value: hideChat,
//               onChanged: (v) => setState(() => hideChat = v),
//             ),
//             _buildSwitchOption(
//               image: "assets/images/eye.png",
//               title: "Hide Chat History",
//               value: hideChatHistory,
//               onChanged: (v) => setState(() => hideChatHistory = v),
//             ),
//             _buildColorOption(
//               image: "assets/images/color.png",
//               title: "Custom Color Chat",
//               color: Colors.blue,
//             ),
//             _buildColorOption(
//               image: "assets/images/galleryEdit.png",
//               title: "Custom Background Chat",
//               color: Colors.white,
//             ),
//             _buildOption(
//               image: "assets/images/report.png",
//               title: "Report",
//               showArrow: false,
//             ),
//             _buildOption(
//               image: "assets/images/block.png",
//               title: "Block",
//               showArrow: false,
//             ),
//             SizedBox(height: size.height * .03),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🔹 Normal option with optional arrow or trailing text
//   Widget _buildOption({
//     required String image,
//     required String title,
//     Widget? trailing,
//     bool showArrow = false,
//   }) {
//     return ListTile(
//       leading: Image.asset(image, width: 30, height: 24),
//       title: Text(title, style: const TextStyle(color: Colors.white)),
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (trailing != null) trailing,
//           if (showArrow)
//             const Icon(
//               Icons.arrow_forward_ios,
//               size: 16,
//               color: Colors.white70,
//             ),
//         ],
//       ),
//     );
//   }

//   // 🔹 Switch option
//   Widget _buildSwitchOption({
//     required String image,
//     required String title,
//     required bool value,
//     required Function(bool) onChanged,
//   }) {
//     return ListTile(
//       leading: Image.asset(image, width: 30, height: 30),
//       title: Text(title, style: const TextStyle(color: Colors.white)),
//       trailing: Switch(
//         value: value,
//         onChanged: onChanged,
//         activeColor: Colors.blue,
//       ),
//     );
//   }

//   // 🔹 Color Option
//   Widget _buildColorOption({
//     required String image,
//     required String title,
//     required Color color,
//   }) {
//     return ListTile(
//       leading: Image.asset(image, width: 30, height: 30),
//       title: Text(title, style: const TextStyle(color: Colors.white)),
//       trailing: Container(
//         width: 20,
//         height: 20,
//         decoration: BoxDecoration(
//           color: color,
//           border: Border.all(color: Colors.white),
//           borderRadius: BorderRadius.circular(4),
//         ),
//       ),
//     );
//   }
// }

// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:chat_app/constants/text.dart';
import 'package:chat_app/folder/add_member_screen.dart';
import 'package:chat_app/folder/groupmediascreen.dart';
import 'package:chat_app/model/groupmodel.dart';
import 'package:chat_app/state/groupstate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final List<Map<String, dynamic>> mediaMessages;
  final List<Map<String, dynamic>> linkMessages;
  final List<Map<String, dynamic>> documentMessages;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.mediaMessages,
    required this.linkMessages,
    required this.documentMessages,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  bool muteNotification = false;
  bool protectedChat = false;
  bool hideChat = false;
  bool hideChatHistory = false;
  late GroupProvider _groupProvider;
  final ImagePicker _imagePicker = ImagePicker();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _groupProvider = Provider.of<GroupProvider>(context, listen: false);
  }

  // Cloudinary Upload Function
  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/dchbirfkc/upload");
      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = 'chat_app'
            ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final resStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonMap = json.decode(resStr);
        return jsonMap['secure_url'] as String?;
      } else {
        print('Cloudinary failed: $resStr');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to upload image")));
        return null;
      }
    } catch (e) {
      print('Cloudinary exception: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error uploading image: $e")));
      return null;
    }
  }

  // Pick Image from Gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        await _updateGroupImage(File(image.path));
      }
    } catch (e) {
      print('Error accessing gallery: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error accessing gallery: $e")));
    }
  }

  // Pick Image from Camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        await _updateGroupImage(File(image.path));
      }
    } catch (e) {
      print('Error accessing camera: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error accessing camera: $e")));
    }
  }

  // Update Group Image
  Future<void> _updateGroupImage(File imageFile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uploadedUrl = await _uploadToCloudinary(imageFile);
      Navigator.pop(context);

      if (uploadedUrl != null) {
        await _groupProvider.updateGroupInfo(
          groupId: widget.groupId,
          imageUrl: uploadedUrl,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group image updated successfully')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating group image: $e')));
    }
  }

  // Show Image Picker Options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff3e3e3e),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeGroupImage();
                  },
                ),
              ],
            ),
          ),
    );
  }

  // Remove Group Image
  Future<void> _removeGroupImage() async {
    try {
      await _groupProvider.updateGroupInfo(
        groupId: widget.groupId,
        imageUrl: '',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group image removed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing group image: $e')));
    }
  }

  Future<void> _leaveGroup() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xff3e3e3e),
            title: const Text(
              'Leave Group?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to leave this group? You won\'t be able to send or receive messages.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await _groupProvider.leaveGroup(widget.groupId);

        // Dismiss loading dialog
        Navigator.pop(context);

        // Navigate back to main screen
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You left the group')));
      } catch (e) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error leaving group: $e')));
      }
    }
  }

  // View Members with admin controls
  void _viewMembers(BuildContext context, ChatGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff3a3a3a),
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (
                  context,
                  scrollController,
                ) => FutureBuilder<List<Map<String, dynamic>>>(
                  future: _groupProvider.getGroupMembers(group.groupId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No members found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final members = snapshot.data!;
                    final isCurrentUserAdmin = group.adminIds.contains(
                      currentUserId,
                    );

                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Group Members',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${members.length} members',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                final memberId = member['uid'] ?? '';
                                final isAdmin = member['isAdmin'] ?? false;
                                final isMe = memberId == currentUserId;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        member['photoUrl'] != null
                                            ? NetworkImage(member['photoUrl'])
                                            : null,
                                    child:
                                        member['photoUrl'] == null
                                            ? Text(
                                              member['name'][0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            )
                                            : null,
                                  ),
                                  title: Text(
                                    isMe
                                        ? '${member['name']} (You)'
                                        : member['name'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    isAdmin ? 'Admin' : 'Member',
                                    style: TextStyle(
                                      color:
                                          isAdmin ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                  trailing:
                                      isCurrentUserAdmin && !isMe
                                          ? PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.white,
                                            ),
                                            color: Color(0xff3e3e3e),
                                            onSelected: (value) async {
                                              switch (value) {
                                                case 'make_admin':
                                                  await _groupProvider
                                                      .makeMemberAdmin(
                                                        widget.groupId,
                                                        memberId,
                                                      );
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '${member['name']} is now an admin',
                                                      ),
                                                    ),
                                                  );
                                                  break;
                                                case 'remove':
                                                  final confirm = await showDialog<
                                                    bool
                                                  >(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          backgroundColor:
                                                              Color(0xff3e3e3e),
                                                          title: Text(
                                                            'Remove Member?',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          content: Text(
                                                            'Remove ${member['name']} from the group?',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                        false,
                                                                      ),
                                                              child: Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                        true,
                                                                      ),
                                                              child: Text(
                                                                'Remove',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );

                                                  if (confirm == true) {
                                                    await _groupProvider
                                                        .removeMemberFromGroup(
                                                          widget.groupId,
                                                          memberId,
                                                        );
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${member['name']} was removed',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  break;
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) => [
                                                  if (!isAdmin)
                                                    PopupMenuItem<String>(
                                                      value: 'make_admin',
                                                      child: Text(
                                                        'Make Admin',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  PopupMenuItem<String>(
                                                    value: 'remove',
                                                    child: Text(
                                                      'Remove from Group',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                          )
                                          : isAdmin
                                          ? Icon(
                                            Icons.star,
                                            color: Colors.blue,
                                            size: 16,
                                          )
                                          : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
    );
  }

  // Add this method to GroupInfoScreen
  void _addMoreMembers(BuildContext context, ChatGroup group) async {
    // Check if current user is admin
    final isAdmin = await _groupProvider.isCurrentUserAdmin(group.groupId);

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can add members to the group'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AddMembersScreen(groupId: group.groupId, groupName: group.name),
      ),
    );

    if (result == true) {
      // Members were added successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Members added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the group info
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff292929),
      appBar: AppBar(
        backgroundColor: const Color(0xff292929),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xff3e3e3e),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xff3e3e3e),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "assets/images/video.png",
              height: size.height * .06,
              width: size.width * .12,
              color: Colors.white,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xff3e3e3e),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<ChatGroup?>(
        stream: _groupProvider.getGroup(widget.groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Group not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final group = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                // Profile Image with Edit Option
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xff40C4FF),
                        backgroundImage:
                            group.imageUrl != null && group.imageUrl!.isNotEmpty
                                ? NetworkImage(group.imageUrl!)
                                : null,
                        child:
                            group.imageUrl == null || group.imageUrl!.isEmpty
                                ? Text(
                                  group.name.isNotEmpty
                                      ? group.name[0].toUpperCase()
                                      : 'G',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xff40C4FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * .03),

                // Group Name with Edit
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      group.name,
                      style: Apptexts.titlestyle.copyWith(color: Colors.white),
                    ),
                    SizedBox(width: size.width * .02),
                    GestureDetector(
                      onTap: () => _showEditGroupDialog(context, group),
                      child: const Icon(Icons.edit, color: Color(0xff40C4FF)),
                    ),
                  ],
                ),

                SizedBox(height: size.height * .01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${group.memberIds.length} members",
                      style: const TextStyle(
                        color: Color(0xffF0F0F3),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * .03),

                // View Members Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () => _viewMembers(context, group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff40C4FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      "View Members",
                      style: Apptexts.subtitlestyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * .03),
                Divider(color: Colors.white24),

                // Group Options
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => Groupmediascreen(
                              mediaMessages: widget.mediaMessages,
                              linkMessages: widget.linkMessages,
                              documentMessages: widget.documentMessages,
                              groupchatId: widget.groupId,
                              groupName: group.name,
                            ),
                      ),
                    );
                  },
                  child: _buildOption(
                    image: "assets/images/media.png",
                    title: "Media, Links & Documents",
                    trailing: Text(
                      "${widget.mediaMessages.length + widget.linkMessages.length + widget.documentMessages.length}",
                      style: TextStyle(color: Colors.white),
                    ),
                    showArrow: true,
                  ),
                ),
                _buildSwitchOption(
                  image: "assets/images/volum.png",
                  title: "Mute Notification",
                  value: muteNotification,
                  onChanged: (v) => setState(() => muteNotification = v),
                ),
                _buildOption(
                  image: "assets/images/bell.png",
                  title: "Custom Notification",
                  showArrow: true,
                ),
                _buildSwitchOption(
                  image: "assets/images/protect.png",
                  title: "Protected Chat",
                  value: protectedChat,
                  onChanged: (v) => setState(() => protectedChat = v),
                ),
                _buildSwitchOption(
                  image: "assets/images/eye.png",
                  title: "Hide Chat",
                  value: hideChat,
                  onChanged: (v) => setState(() => hideChat = v),
                ),
                _buildSwitchOption(
                  image: "assets/images/eye.png",
                  title: "Hide Chat History",
                  value: hideChatHistory,
                  onChanged: (v) => setState(() => hideChatHistory = v),
                ),
                _buildOption(
                  image: "assets/images/group.png",
                  title: "Add more members",
                  showArrow: true,
                  onTap: () => _addMoreMembers(context, group),
                ),
                _buildColorOption(
                  image: "assets/images/color.png",
                  title: "Custom Color Chat",
                  color: Colors.blue,
                ),
                _buildColorOption(
                  image: "assets/images/galleryEdit.png",
                  title: "Custom Background Chat",
                  color: Colors.white,
                ),
                _buildOption(
                  image: "assets/images/report.png",
                  title: "Report",
                  showArrow: false,
                ),
                GestureDetector(
                  onTap: _leaveGroup,
                  child: ListTile(
                    leading: Image.asset(
                      "assets/images/block.png",
                      width: 30,
                      height: 30,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Leave Group",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(height: size.height * .03),
              ],
            ),
          );
        },
      ),
    );
  }

  // Edit Group Dialog
  void _showEditGroupDialog(BuildContext context, ChatGroup group) {
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(
      text: group.description,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xff3a3a3a),
            title: const Text(
              'Edit Group',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _groupProvider.updateGroupInfo(
                      groupId: group.groupId,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Group updated successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating group: $e')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  // 🔹 Normal option with optional arrow or trailing text
  // Update the _buildOption method in GroupInfoScreen to include onTap
  Widget _buildOption({
    required String image,
    required String title,
    Widget? trailing,
    bool showArrow = false,
    VoidCallback? onTap, // Add this
  }) {
    return ListTile(
      leading: Image.asset(image, width: 30, height: 24),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          if (showArrow)
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white70,
            ),
        ],
      ),
      onTap: onTap, // Add this
    );
  }

  // 🔹 Switch option
  Widget _buildSwitchOption({
    required String image,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Image.asset(image, width: 30, height: 30),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  // 🔹 Color Option
  Widget _buildColorOption({
    required String image,
    required String title,
    required Color color,
  }) {
    return ListTile(
      leading: Image.asset(image, width: 30, height: 30),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
