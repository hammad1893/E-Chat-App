// import 'dart:async';
// import 'dart:core';
// import 'dart:io';
// import 'dart:math';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:chat_app/constants/text.dart';
// import 'package:chat_app/constants/utils.dart';
// import 'package:chat_app/homepage.dart/contactdetail.dart';
// import 'package:chat_app/model/chatmodel.dart';
// import 'package:chat_app/state/chatstate.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_contacts/flutter_contacts.dart'; // UPDATED
// import 'package:permission_handler/permission_handler.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';
// import 'package:shimmer/shimmer.dart';

// class Chatscreen extends StatefulWidget {
//   final String name;
//   final String image;
//   final String receiverId;
//   final String phone;

//   const Chatscreen({
//     super.key,
//     required this.name,
//     required this.image,
//     required this.receiverId,
//     required this.phone,
//     required senderId,
//   });

//   @override
//   State<Chatscreen> createState() => _ChatscreenState();
// }

// class _ChatscreenState extends State<Chatscreen> {
//   final TextEditingController _msgController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final ImagePicker _imagePicker = ImagePicker();
//   final AudioRecorder _audioRecorder = AudioRecorder();
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid;
//   late String chatId;
//   late Stream<Map<String, dynamic>> _receiverStatusStream;
//   bool _isReceiverOnline = false;
//   Timestamp? _receiverLastSeen;
//   bool _isLoadingMessages = true;
//   bool _isRecording = false;
//   // ignore: unused_field
//   String? _currentAudioPath;
//   bool _isPlaying = false;
//   Duration _audioDuration = Duration.zero;
//   Duration _audioPosition = Duration.zero;
//   String _currentPlayingUrl = '';
//   bool _isUserBlocked = false;
//   bool _isCheckingBlockStatus = true;
//   bool _hasBlockedReceiver = false;
//   bool _isSelecting = false;
//   Set<String> _selectedMessages = {};
//   List<MessageModel> _currentMessages = [];

//   @override
//   @override
//   void initState() {
//     super.initState();
//     chatId = getChatId(currentUserId, widget.receiverId);
//     _initializeStatusStream();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final chatProvider = Provider.of<ChatProvider>(context, listen: false);
//       chatProvider.markMessagesAsRead(chatId, currentUserId);
//       _checkBlockingStatus();
//     });

//     _setUserOnlineStatus(true);
//     _setupAudioPlayerListeners();
//   }

//  void _setupAudioPlayerListeners() {
//     _audioPlayer.onPlayerComplete.listen((event) {
//       if (mounted) {
//         setState(() {
//           _isPlaying = false;
//           _audioPosition = Duration.zero;
//           _currentPlayingUrl = '';
//         });
//       }
//     });
//   }

//    void _initializeStatusStream() {
//     _receiverStatusStream = FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.receiverId)
//         .snapshots()
//         .map((doc) {
//           if (doc.exists) {
//             return doc.data() as Map<String, dynamic>;
//           }
//           return {};
//         });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _initializeStatusStream();
//   }

//   Future<void> _setUserOnlineStatus(bool isOnline) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUserId)
//           .update({
//             'isOnline': isOnline,
//             'lastSeen': FieldValue.serverTimestamp(),
//           });
//     } catch (e) {
//       print('Error updating online status: $e');
//     }
//   }

//   String getChatId(String user1, String user2) {
//     List<String> users = [user1, user2];
//     users.sort();
//     return "${users[0]}_${users[1]}";
//   }

//   String formatTimestamp(DateTime timestamp) {
//     return DateFormat("hh:mm a").format(timestamp);
//   }

//   String formatLastSeen(Timestamp? lastSeen) {
//     if (lastSeen == null) return "Last seen unknown";

//     final now = DateTime.now();
//     final seenTime = lastSeen.toDate();
//     final difference = now.difference(seenTime);

//     if (difference.inSeconds < 60) return "Last seen just now";
//     if (difference.inMinutes < 60)
//       return "Last seen ${difference.inMinutes}m ago";
//     if (difference.inHours < 24) return "Last seen ${difference.inHours}h ago";
//     if (difference.inDays < 7) return "Last seen ${difference.inDays}d ago";

//     return "Last seen ${DateFormat("MMM dd, yyyy").format(seenTime)}";
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         0,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   void _toggleMessageSelection(String messageId) {
//     setState(() {
//       if (_selectedMessages.contains(messageId)) {
//         _selectedMessages.remove(messageId);
//       } else {
//         _selectedMessages.add(messageId);
//       }

//       if (_selectedMessages.isEmpty) {
//         _isSelecting = false;
//       } else {
//         _isSelecting = true;
//       }
//     });
//   }

//   void _clearSelection() {
//     setState(() {
//       _selectedMessages.clear();
//       _isSelecting = false;
//     });
//   }

//   Future<void> _deleteSelectedMessages() async {
//     if (_selectedMessages.isEmpty) return;

//     final chatProvider = Provider.of<ChatProvider>(context, listen: false);

//     try {
//       await chatProvider.deleteMultipleMessages(chatId, _selectedMessages.toList());
//       _clearSelection();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Deleted ${_selectedMessages.length} message(s)'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error deleting messages: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//     Future<void> _checkBlockingStatus() async {
//     try {
//       final chatProvider = Provider.of<ChatProvider>(context, listen: false);

//       final hasBlocked = await chatProvider.isUserBlocked(widget.receiverId);
//       final isBlockedByReceiver = await chatProvider.isBlockedByUser(widget.receiverId);

//       setState(() {
//         _hasBlockedReceiver = hasBlocked;
//         _isUserBlocked = isBlockedByReceiver;
//         _isCheckingBlockStatus = false;
//       });
//     } catch (e) {
//       print('Error checking block status: $e');
//       setState(() {
//         _isCheckingBlockStatus = false;
//       });
//     }
//   }

//   // UPDATED: Enhanced unblock dialog
//   void _showUnblockDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xff3e3e3e),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         title: Text(
//           'Unblock ${widget.name}?',
//           style: const TextStyle(color: Colors.white, fontSize: 18),
//         ),
//         content: Text(
//           'You will be able to send and receive messages from this contact again.',
//           style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               'CANCEL',
//               style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               try {
//                 final chatProvider = Provider.of<ChatProvider>(context, listen: false);
//                 await chatProvider.unblockUser(widget.receiverId);

//                 setState(() {
//                   _hasBlockedReceiver = false;
//                 });

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Unblocked ${widget.name}'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Error unblocking: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: const Text(
//               'UNBLOCK',
//               style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//    Widget _buildBlockedInputUI(Size size) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       color: const Color(0xff292929),
//       child: GestureDetector(
//         onTap: _showUnblockDialog,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             color: const Color(0xff3e3e3e),
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.red.withOpacity(0.3)),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.block, color: Colors.red.withOpacity(0.8), size: 20),
//               const SizedBox(width: 12),
//               Text(
//                 'You blocked this contact. Tap to unblock',
//                 style: TextStyle(
//                   color: Colors.red.withOpacity(0.9),
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<String?> _uploadToCloudinary(File file) async {
//     try {
//       final url = Uri.parse("https://api.cloudinary.com/v1_1/dchbirfkc/upload");
//       final request =
//           http.MultipartRequest('POST', url)
//             ..fields['upload_preset'] = 'chat_app'
//             ..files.add(await http.MultipartFile.fromPath('file', file.path));

//       final response = await request.send();
//       print('Cloudinary upload status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final resStr = await response.stream.bytesToString();
//         final jsonMap = json.decode(resStr);
//         print('Cloudinary response: $jsonMap');
//         return jsonMap['secure_url'];
//       } else {
//         final errorResponse = await response.stream.bytesToString();
//         print('Cloudinary error: $errorResponse');
//         SnackbarMessage.failedsnack("Failed to upload file", context);
//         return null;
//       }
//     } catch (e) {
//       print('Cloudinary exception: $e');
//       SnackbarMessage.failedsnack("Error uploading file: $e", context);
//       return null;
//     }
//   }

//   Future<void> _pickImageFromCamera() async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//       );
//       if (image != null) {
//         _sendMediaMessage(File(image.path), 'image');
//       }
//     } catch (e) {
//       SnackbarMessage.failedsnack('Error accessing camera: $e', context);
//       print('Error accessing camera: $e');
//     }
//   }

//   Future<void> _pickImageFromGallery() async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//       );
//       if (image != null) {
//         _sendMediaMessage(File(image.path), 'image');
//       }
//     } catch (e) {
//       SnackbarMessage.failedsnack('Error accessing gallery: $e', context);
//       print('Error accessing gallery: $e');
//     }
//   }

//   Future<void> _pickDocument() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.any,
//         allowMultiple: false,
//       );

//       if (result != null && result.files.single.path != null) {
//         _sendMediaMessage(File(result.files.single.path!), 'document');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error picking document: $e')));
//       print('Error picking document: $e');
//     }
//   }

//   Future<void> _openDocument(String documentUrl, String fileName) async {
//     try {
//       // showDialog(
//       //   context: context,
//       //   barrierDismissible: false,
//       //   builder:
//       //       (context) => Center(
//       //         child: Column(
//       //           mainAxisSize: MainAxisSize.min,
//       //           children: [
//       //             CircularProgressIndicator(color: Colors.white),
//       //             SizedBox(height: 16),
//       //             Text(
//       //               'Opening document...',
//       //               style: TextStyle(color: Colors.white),
//       //             ),
//       //           ],
//       //         ),
//       //       ),
//       // );

//       // Download file to temp directory
//       final response = await http.get(Uri.parse(documentUrl));
//       final tempDir = await getTemporaryDirectory();
//       final extension = documentUrl.split('.').last.split('?').first;
//       final file = File('${tempDir.path}/$fileName.$extension');
//       await file.writeAsBytes(response.bodyBytes);

//       Navigator.pop(context); // Close loading dialog

//       // Open file with system default app
//       final result = await OpenFilex.open(file.path);

//       if (result.type != ResultType.done) {
//         throw 'Failed to open document: ${result.message}';
//       }
//     } catch (e) {
//       if (Navigator.canPop(context)) Navigator.pop(context);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error opening document: $e'),
//           backgroundColor: Colors.red,
//           action: SnackBarAction(
//             label: 'RETRY',
//             textColor: Colors.white,
//             onPressed: () => _openDocument(documentUrl, fileName),
//           ),
//         ),
//       );
//     }
//   }

//   Widget _buildShimmerLoadingState() {
//     return ListView.builder(
//       reverse: true,
//       padding: const EdgeInsets.all(10),
//       itemCount: 6,
//       itemBuilder: (context, index) {
//         final isMe = index % 2 == 0;
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Row(
//             mainAxisAlignment:
//                 isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               Shimmer.fromColors(
//                 baseColor:
//                     isMe
//                         ? const Color(0xff1565C0).withOpacity(0.3)
//                         : Colors.white.withOpacity(0.2),
//                 highlightColor:
//                     isMe
//                         ? const Color(0xff1565C0).withOpacity(0.5)
//                         : Colors.white.withOpacity(0.4),
//                 child: Container(
//                   width: 200,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Duration _recordingDuration = Duration.zero;
//   Timer? _recordingTimer;

//   // Update your _startRecording method
//   Future<void> _startRecording() async {
//     try {
//       if (await _audioRecorder.hasPermission()) {
//         final tempDir = await getTemporaryDirectory();
//         final filePath =
//             '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

//         await _audioRecorder.start(const RecordConfig(), path: filePath);

//         // Start timer for recording duration
//         _recordingDuration = Duration.zero;
//         _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
//           setState(() {
//             _recordingDuration += Duration(seconds: 1);
//           });
//         });

//         setState(() {
//           _isRecording = true;
//           _currentAudioPath = filePath;
//         });
//       }
//     } catch (e) {
//       SnackbarMessage.failedsnack('Error starting recording: $e', context);
//       print('Error starting recording: $e');
//     }
//   }

//   // Update your _stopRecording method
//   Future<void> _stopRecording() async {
//     try {
//       // Stop the timer first
//       _recordingTimer?.cancel();
//       _recordingTimer = null;

//       final path = await _audioRecorder.stop();
//       setState(() {
//         _isRecording = false;
//         _recordingDuration = Duration.zero;
//       });

//       if (path != null) {
//         _sendMediaMessage(File(path), 'audio');
//       }
//     } catch (e) {
//       print('Error stopping recording: $e');
//       SnackbarMessage.failedsnack('Error stopping recording: $e', context);
//     }
//   }

//   // Fix the _buildRecordingUI method
//   Widget _buildRecordingUI(Size size) {
//     final minutes = _recordingDuration.inMinutes
//         .remainder(60)
//         .toString()
//         .padLeft(2, '0');
//     final seconds = _recordingDuration.inSeconds
//         .remainder(60)
//         .toString()
//         .padLeft(2, '0');
//     final durationText = '$minutes:$seconds';

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//       decoration: BoxDecoration(
//         color: Color(0xff3e3e3e),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           // Delete button
//           IconButton(
//             icon: Icon(Icons.delete, color: Colors.red),
//             onPressed: () {
//               setState(() {
//                 _isRecording = false;
//                 _recordingTimer?.cancel();
//                 _recordingTimer = null;
//                 _recordingDuration = Duration.zero;
//                 _audioRecorder.stop();
//               });
//             },
//           ),

//           SizedBox(width: 10),
//           Expanded(
//             child: SizedBox(
//               height: 30,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: List.generate(12, (index) {
//                   final animationValue =
//                       (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
//                   final waveHeights = List.generate(12, (i) {
//                     final baseHeight = 8 + (i % 3) * 4;
//                     final animatedHeight =
//                         baseHeight +
//                         (sin(animationValue * 2 * pi + i * 0.5) * 6).toInt();
//                     return animatedHeight.clamp(8.0, 20.0).toDouble();
//                   });

//                   return AnimatedContainer(
//                     duration: Duration(milliseconds: 200),
//                     width: 3,
//                     height: waveHeights[index],
//                     decoration: BoxDecoration(
//                       color: Color(0xff40C4FF),
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   );
//                 }),
//               ),
//             ),
//           ),
//           SizedBox(width: 10),
//           Text(
//             durationText,
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),

//           SizedBox(width: 10),
//           IconButton(
//             icon: Icon(Icons.play_arrow, color: Colors.grey),
//             onPressed: null,
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _toggleAudioPlayback(String audioUrl) async {
//     try {
//       if (_currentPlayingUrl == audioUrl && _isPlaying) {
//         await _audioPlayer.pause();
//         setState(() {
//           _isPlaying = false;
//         });
//       } else {
//         if (_isPlaying) {
//           await _audioPlayer.stop();
//         }
//         await _audioPlayer.play(UrlSource(audioUrl));

//         setState(() {
//           _currentPlayingUrl = audioUrl;
//           _isPlaying = true;
//           _audioPosition = Duration.zero;
//         });
//         Future.delayed(Duration(milliseconds: 100), () async {
//           final duration = await _audioPlayer.getDuration();
//           if (mounted && duration != null) {
//             setState(() {
//               _audioDuration = duration;
//             });
//           }
//         });
//         _audioPlayer.onPositionChanged.listen((Duration position) {
//           if (mounted) {
//             setState(() {
//               _audioPosition = position;
//             });
//           }
//         });
//         _audioPlayer.onPlayerComplete.listen((event) {
//           if (mounted) {
//             setState(() {
//               _isPlaying = false;
//               _audioPosition = Duration.zero;
//               _currentPlayingUrl = '';
//             });
//           }
//         });
//       }
//     } catch (e) {
//       print('Error playing audio: $e');
//     }
//   }

//   List<Map<String, dynamic>> _getMediaMessages(List<MessageModel> messages) {
//     return messages
//         .where(
//           (message) =>
//               message.mediaUrl != null &&
//               message.mediaUrl!.isNotEmpty &&
//               (message.messageType == 'image' ||
//                   message.messageType == 'video'),
//         )
//         .map(
//           (message) => {
//             'mediaUrl': message.mediaUrl,
//             'text': message.text,
//             'timestamp': message.timestamp,
//           },
//         )
//         .toList();
//   }

//   List<Map<String, dynamic>> _getLinkMessages(List<MessageModel> messages) {
//     final urlRegex = RegExp(
//       r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
//       caseSensitive: false,
//     );

//     return messages
//         .where((message) => urlRegex.hasMatch(message.text))
//         .map(
//           (message) => {'text': message.text, 'timestamp': message.timestamp},
//         )
//         .toList();
//   }

//   List<Map<String, dynamic>> _getDocumentMessages(List<MessageModel> messages) {
//     return messages
//         .where((message) => message.messageType == 'document')
//         .map(
//           (message) => {
//             'text': message.text,
//             'mediaUrl': message.mediaUrl,
//             'timestamp': message.timestamp,
//           },
//         )
//         .toList();
//   }

//   Future<void> _pickContact() async {
//     try {
//       final status = await Permission.contacts.request();

//       if (status.isGranted) {
//         final Contact? contact = await FlutterContacts.openExternalPick();

//         if (contact != null) {
//           // Check if user can send message before sending contact
//           final chatProvider = Provider.of<ChatProvider>(
//             context,
//             listen: false,
//           );
//           final canSend = await chatProvider.canSendMessage(widget.receiverId);

//           if (!canSend) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   'Cannot share contact. User may have blocked you or you have blocked this user.',
//                 ),
//                 backgroundColor: Colors.red,
//               ),
//             );
//             return;
//           }

//           final contactInfo = {
//             'name': contact.displayName,
//             'phones': contact.phones.map((phone) => phone.number).toList(),
//             'emails': contact.emails.map((email) => email.address).toList(),
//           };

//           await chatProvider.sendMessage(
//             senderId: currentUserId,
//             receiverId: widget.receiverId,
//             text: '📞 Contact: ${contact.displayName}',
//             messageType: 'contact',
//             contactInfo: contactInfo,
//           );
//         }
//       } else {
//         SnackbarMessage.failedsnack('Contacts permission denied', context);
//       }
//     } catch (e) {
//       String errorMessage = 'Error picking contact';
//       if (e.toString().contains('blocked')) {
//         errorMessage =
//             'Cannot share contact. User may have blocked you or you have blocked this user.';
//       }

//       SnackbarMessage.failedsnack('$errorMessage: $e', context);
//     }
//   }

//   Future<void> _sendMediaMessage(File file, String type) async {
//     final chatProvider = Provider.of<ChatProvider>(context, listen: false);

//     // Check if user can send message before uploading
//     try {
//       final canSend = await chatProvider.canSendMessage(widget.receiverId);
//       if (!canSend) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Cannot send media. User may have blocked you or you have blocked this user.',
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error checking permissions: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Center(child: CircularProgressIndicator());
//       },
//     );

//     try {
//       final uploadedUrl = await _uploadToCloudinary(file);
//       Navigator.pop(context);

//       if (uploadedUrl != null) {
//         String text = '';
//         switch (type) {
//           case 'image':
//             text = '📷 Image';
//             break;
//           case 'document':
//             text = '📄 Document';
//             break;
//           case 'audio':
//             text = '🎤 Voice message';
//             break;
//         }

//         await chatProvider.sendMessage(
//           senderId: currentUserId,
//           receiverId: widget.receiverId,
//           text: text,
//           mediaUrl: uploadedUrl,
//           messageType: type,
//         );
//       }
//     } catch (e) {
//       Navigator.pop(context);

//       String errorMessage = 'Error sending media';
//       if (e.toString().contains('blocked')) {
//         errorMessage =
//             'Cannot send media. User may have blocked you or you have blocked this user.';
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('$errorMessage: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Widget _getMessageStatusIcon(bool isMe, bool isRead, bool isReceiverOnline, String receiverId) {
//     if (!isMe) return SizedBox.shrink();

//     // Check if receiver can receive messages (not blocked by current user)
//     final canReceive = !_hasBlockedReceiver;

//     if (!canReceive) {
//       // Show single tick (like WhatsApp) when user is blocked
//       return Icon(Icons.done, color: Colors.grey[300], size: 16);
//     }

//     if (isRead) {
//       return Icon(Icons.done_all, color: Colors.blue, size: 16);
//     } else if (isReceiverOnline) {
//       return Icon(Icons.done_all, color: Colors.grey[300], size: 16);
//     } else {
//       return Icon(Icons.done, color: Colors.grey[300], size: 16);
//     }
//   }
//   Widget _buildSelectionHeader(Size size) {
//     return Container(
//       height: size.height * .08,
//       width: double.infinity,
//       decoration: const BoxDecoration(color: Color(0xff292929)),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           children: [
//             IconButton(
//               icon: Icon(Icons.close, color: Colors.white),
//               onPressed: _clearSelection,
//             ),
//             SizedBox(width: 16),
//             Text(
//               '${_selectedMessages.length} selected',
//               style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//             Spacer(),
//             IconButton(
//               icon: Icon(Icons.delete, color: Colors.red),
//               onPressed: _deleteSelectedMessages,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//     @override
//   void dispose() {
//     _recordingTimer?.cancel();
//     _recordingTimer = null;
//     _audioPlayer.dispose();
//     _setUserOnlineStatus(false);
//     _msgController.dispose();
//     _scrollController.dispose();
//     _audioRecorder.dispose();
//     super.dispose();
//   }

//    @override
//   Widget build(BuildContext context) {
//     final chatProvider = Provider.of<ChatProvider>(context);
//     Size size = MediaQuery.of(context).size;

//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: const Color(0xff2c2d3a),
//         body: Column(
//           children: [
//             // NEW: Selection header (appears when selecting messages)
//             if (_isSelecting) _buildSelectionHeader(size),

//             // Header
//             StreamBuilder<Map<String, dynamic>>(
//               stream: _receiverStatusStream,
//               builder: (context, snapshot) {
//                 if (snapshot.hasData) {
//                   final data = snapshot.data!;
//                   _isReceiverOnline = data['isOnline'] ?? false;
//                   _receiverLastSeen = data['lastSeen'] as Timestamp?;
//                 }

//                 final statusText = _isReceiverOnline ? "Online" : formatLastSeen(_receiverLastSeen);

//                 return Container(
//                   height: size.height * .1,
//                   width: double.infinity,
//                   decoration: const BoxDecoration(color: Color(0xff292929)),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                     child: Row(
//                       children: [
//                         // Back button with different behavior when selecting
//                         InkWell(
//                           onTap: _isSelecting ? _clearSelection : () => Navigator.pop(context),
//                           child: Container(
//                             height: size.height * .05,
//                             width: size.width * .1,
//                             decoration: const BoxDecoration(
//                               color: Color(0xff3e3e3e),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(
//                               _isSelecting ? Icons.close : Icons.arrow_back,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: size.width * .02),
//                         Stack(
//                           children: [
//                             CircleAvatar(
//                               radius: 23,
//                               backgroundImage: widget.image.startsWith("http")
//                                   ? NetworkImage(widget.image)
//                                   : AssetImage(widget.image) as ImageProvider,
//                             ),
//                             if (_isReceiverOnline)
//                               Positioned(
//                                 right: 0,
//                                 bottom: 0,
//                                 child: Container(
//                                   width: 12,
//                                   height: 12,
//                                   decoration: BoxDecoration(
//                                     color: Colors.green,
//                                     shape: BoxShape.circle,
//                                     border: Border.all(color: Colors.white, width: 2),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(width: size.width * .03),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 _isSelecting ? '${_selectedMessages.length} selected' : widget.name,
//                                 softWrap: true,
//                                 style: Apptexts.titlestyle.copyWith(
//                                   color: Colors.white,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               if (!_isSelecting)
//                                 Text(
//                                   statusText,
//                                   style: Apptexts.bodystyle.copyWith(
//                                     color: _isReceiverOnline ? Colors.green : Colors.white54,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                         if (!_isSelecting) ...[
//                           SizedBox(width: size.width * .02),
//                           Image.asset(
//                             "assets/images/video.png",
//                             height: size.height * .06,
//                             width: size.width * .12,
//                           ),
//                           SizedBox(width: size.width * .015),
//                           GestureDetector(
//                             onTap: () {},
//                             child: Icon(Icons.call, color: Colors.white, size: 25),
//                           ),
//                           SizedBox(width: size.width * .015),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => StreamBuilder<List<MessageModel>>(
//                                     stream: chatProvider.getMessagesStream(chatId),
//                                     builder: (context, snapshot) {
//                                       if (snapshot.hasData) {
//                                         _currentMessages = snapshot.data!;
//                                         return ContactInfoScreen(
//                                           contactName: widget.name,
//                                           contactPhone: widget.phone,
//                                           contactImageUrl: widget.image,
//                                           chatId: chatId,
//                                           currentUserId: currentUserId,
//                                           mediaMessages: _getMediaMessages(_currentMessages),
//                                           linkMessages: _getLinkMessages(_currentMessages),
//                                           documentMessages: _getDocumentMessages(_currentMessages),
//                                         );
//                                       }
//                                       return Scaffold(
//                                         backgroundColor: const Color(0xff292929),
//                                         body: Center(child: CircularProgressIndicator()),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               );
//                             },
//                             child: Icon(Icons.more_vert, color: Colors.white, size: 25),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),

//             // Messages area
//             Expanded(
//               child: StreamBuilder<List<MessageModel>>(
//                 stream: chatProvider.getMessagesStream(chatId),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting && _isLoadingMessages) {
//                     return _buildShimmerLoadingState();
//                   }

//                   if (snapshot.hasError) {
//                     _isLoadingMessages = false;
//                     return _buildShimmerLoadingState();
//                   }

//                   final messages = snapshot.data ?? [];
//                   _currentMessages = messages; // Store for selection

//                   if (messages.isEmpty && !_isLoadingMessages) {
//                     return Center(
//                       child: Text("No messages yet", style: TextStyle(color: Colors.white54)),
//                     );
//                   }

//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     _scrollToBottom();
//                   });

//                   return ListView.builder(
//                     controller: _scrollController,
//                     reverse: true,
//                     shrinkWrap: true,
//                     padding: const EdgeInsets.all(10),
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isMe = message.senderId == currentUserId;
//                       final time = formatTimestamp(message.timestamp);
//                       final isSelected = _selectedMessages.contains(message.messageId);

//                       // Build message with selection capability
//                       Widget messageWidget;
//                       if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
//                         messageWidget = _buildMediaMessage(message, isMe, time);
//                       } else if (message.messageType == 'contact') {
//                         messageWidget = _buildContactMessage(message, isMe, time);
//                       } else {
//                         messageWidget = isMe
//                             ? _buildSentMessage(message.text, time, message.isRead, _isReceiverOnline, widget.receiverId)
//                             : _buildReceivedMessage(message.text, time);
//                       }

//                       return GestureDetector(
//                         onLongPress: () => _toggleMessageSelection(message.messageId),
//                         onTap: _isSelecting ? () => _toggleMessageSelection(message.messageId) : null,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: messageWidget,
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),

//             const Divider(color: Color(0xff595a6d), height: 1),

//             // Conditional input based on block status
//             _hasBlockedReceiver
//                 ? _buildBlockedInputUI(size)
//                 : _buildMessageInput(chatProvider, size),
//           ],
//         ),
//       ),
//     );
//   }

//   // / Replace your _buildMediaMessage method with this improved version
//   Widget _buildMediaMessage(MessageModel message, bool isMe, String time) {
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.6,
//         ),
//         decoration: BoxDecoration(
//           color: isMe ? const Color(0xff1565C0) : Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             if (message.messageType == 'image')
//               ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(16),
//                   topRight: Radius.circular(16),
//                   bottomLeft: Radius.circular(8),
//                   bottomRight: Radius.circular(8),
//                 ),
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder:
//                             (context) => FullScreenImageViewer(
//                               imageUrl: message.mediaUrl!,
//                               heroTag: message.mediaUrl!,
//                             ),
//                       ),
//                     );
//                   },
//                   child: Hero(
//                     tag: message.mediaUrl!,
//                     child: CachedNetworkImage(
//                       imageUrl: message.mediaUrl!,
//                       width: double.infinity,
//                       height: 200,
//                       fit: BoxFit.cover,
//                       placeholder:
//                           (context, url) => Shimmer.fromColors(
//                             baseColor: Colors.grey[300]!,
//                             highlightColor: Colors.grey[100]!,
//                             child: Container(
//                               width: double.infinity,
//                               height: 200,
//                               color: Colors.white,
//                             ),
//                           ),
//                       errorWidget:
//                           (context, url, error) => Container(
//                             width: double.infinity,
//                             height: 200,
//                             color: Colors.grey[300],
//                             child: const Center(
//                               child: Icon(Icons.broken_image, size: 50),
//                             ),
//                           ),
//                       memCacheHeight: 400,
//                       memCacheWidth: 400,
//                     ),
//                   ),
//                 ),
//               )
//             else if (message.messageType == 'audio')
//               _buildAudioPlayerForMedia(message.mediaUrl!, isMe, time)
//             else if (message.messageType == 'document')
//               GestureDetector(
//                 onTap:
//                     () => _openDocument(
//                       message.mediaUrl!,
//                       _getDocumentName(message.text),
//                     ),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color:
//                               isMe
//                                   ? Colors.white.withOpacity(0.2)
//                                   : Colors.grey.withOpacity(0.3),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(
//                           _getDocumentIcon(message.mediaUrl),
//                           size: 28,
//                           color: isMe ? Colors.white : Colors.grey[700],
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _getDocumentName(message.text),
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: isMe ? Colors.white : Colors.black87,
//                                 fontSize: 14,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               'Tap to open',
//                               style: TextStyle(
//                                 color:
//                                     isMe
//                                         ? Colors.white.withOpacity(0.7)
//                                         : Colors.grey[600],
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Icon(
//                         Icons.open_in_new,
//                         size: 16,
//                         color: isMe ? Colors.white70 : Colors.grey[600],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             if (message.messageType != 'audio')
//               Padding(
//                 padding: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       time,
//                       style: TextStyle(
//                         color:
//                             isMe
//                                 ? Colors.white.withOpacity(0.7)
//                                 : Colors.grey[600],
//                         fontSize: 10,
//                       ),
//                     ),
//                     if (isMe) const SizedBox(width: 5),
//                     if (isMe)
//                       Icon(
//                         message.isRead ? Icons.done_all : Icons.done,
//                         size: 12,
//                         color:
//                             message.isRead
//                                 ? Colors.blue[200]
//                                 : Colors.white.withOpacity(0.7),
//                       ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAudioPlayerForMedia(String audioUrl, bool isMe, String time) {
//     final bool isCurrentlyPlaying =
//         _currentPlayingUrl == audioUrl && _isPlaying;
//     final Duration position =
//         isCurrentlyPlaying ? _audioPosition : Duration.zero;

//     final String durationText =
//         isCurrentlyPlaying
//             ? '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}'
//             : '0:00';

//     final double progress =
//         _audioDuration.inMilliseconds > 0
//             ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
//             : 0.0;

//     return Container(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         children: [
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               InkWell(
//                 onTap: () => _toggleAudioPlayback(audioUrl),
//                 borderRadius: BorderRadius.circular(20),
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color:
//                         isMe
//                             ? Colors.white.withOpacity(0.2)
//                             : const Color(0xff1565C0).withOpacity(0.1),
//                   ),
//                   child: Icon(
//                     isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
//                     color: isMe ? Colors.white : const Color(0xff1565C0),
//                     size: 24,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Container(
//                   height: 30,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: List.generate(15, (index) {
//                           final heights = [
//                             6,
//                             10,
//                             14,
//                             18,
//                             16,
//                             12,
//                             8,
//                             6,
//                             10,
//                             14,
//                             18,
//                             12,
//                             8,
//                             10,
//                             6,
//                           ];
//                           return Container(
//                             width: 3,
//                             height: heights[index % heights.length].toDouble(),
//                             decoration: BoxDecoration(
//                               color:
//                                   isMe
//                                       ? Colors.white.withOpacity(0.4)
//                                       : Colors.grey.withOpacity(0.5),
//                               borderRadius: BorderRadius.circular(2),
//                             ),
//                           );
//                         }),
//                       ),
//                       if (isCurrentlyPlaying || progress > 0)
//                         ClipRect(
//                           child: Align(
//                             alignment: Alignment.centerLeft,
//                             widthFactor: progress.clamp(0.0, 1.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: List.generate(15, (index) {
//                                 final heights = [
//                                   6,
//                                   10,
//                                   14,
//                                   18,
//                                   16,
//                                   12,
//                                   8,
//                                   6,
//                                   10,
//                                   14,
//                                   18,
//                                   12,
//                                   8,
//                                   10,
//                                   6,
//                                 ];
//                                 return Container(
//                                   width: 3,
//                                   height:
//                                       heights[index % heights.length]
//                                           .toDouble(),
//                                   decoration: BoxDecoration(
//                                     color:
//                                         isMe
//                                             ? Colors.white
//                                             : const Color(0xff1565C0),
//                                     borderRadius: BorderRadius.circular(2),
//                                   ),
//                                 );
//                               }),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 durationText,
//                 style: TextStyle(
//                   color:
//                       isMe ? Colors.white.withOpacity(0.9) : Colors.grey[700],
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 4),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Text(
//                 time,
//                 style: TextStyle(
//                   color:
//                       isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600],
//                   fontSize: 10,
//                 ),
//               ),
//               if (isMe) const SizedBox(width: 5),
//               if (isMe)
//                 Icon(
//                   Icons.done_all,
//                   size: 12,
//                   color: Colors.white.withOpacity(0.7),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getDocumentIcon(String? mediaUrl) {
//     if (mediaUrl == null) return Icons.insert_drive_file;

//     final extension = mediaUrl.split('.').last.toLowerCase();
//     switch (extension) {
//       case 'pdf':
//         return Icons.picture_as_pdf;
//       case 'doc':
//       case 'docx':
//         return Icons.description;
//       case 'xls':
//       case 'xlsx':
//         return Icons.table_chart;
//       case 'ppt':
//       case 'pptx':
//         return Icons.slideshow;
//       case 'txt':
//         return Icons.text_fields;
//       case 'zip':
//       case 'rar':
//         return Icons.folder_zip;
//       default:
//         return Icons.insert_drive_file;
//     }
//   }

//   String _getDocumentName(String? text) {
//     if (text == null || text.isEmpty) return 'Document';
//     if (text.startsWith('📄 Document')) return 'Document';
//     return text;
//   }

//   Widget _buildContactMessage(MessageModel message, bool isMe, String time) {
//     final contactInfo = message.contactInfo ?? {};
//     final contactName = contactInfo['name'] ?? 'Unknown';
//     final phones = contactInfo['phones'] ?? [];

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isMe ? const Color(0xff1565C0) : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.contact_phone,
//                   color: isMe ? Colors.white : Colors.blue,
//                 ),
//                 SizedBox(width: 8),
//                 Text(
//                   'Contact: $contactName',
//                   style: TextStyle(
//                     color: isMe ? Colors.white : Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             if (phones.isNotEmpty) ...[
//               SizedBox(height: 8),
//               Text(
//                 'Phone: ${phones.first}',
//                 style: TextStyle(
//                   color: isMe ? Colors.white70 : Colors.grey[700],
//                 ),
//               ),
//             ],
//             SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   time,
//                   style: TextStyle(
//                     color: isMe ? Colors.white70 : Colors.grey[600],
//                     fontSize: 12,
//                   ),
//                 ),
//                 if (isMe) SizedBox(width: 5),
//                 if (isMe)
//                   _getMessageStatusIcon(
//                     true,
//                     message.isRead,
//                     _isReceiverOnline,
//                     message.receiverId,
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReceivedMessage(String text, String time) {
//     Size size = MediaQuery.of(context).size;
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//         constraints: BoxConstraints(maxWidth: size.width * 0.57),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(size.width * 0.05),
//             topRight: Radius.circular(size.width * 0.05),
//             bottomRight: Radius.circular(size.width * 0.05),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               text,
//               style: Apptexts.subtitlestyle.copyWith(color: Color(0xff2C2D3A)),
//             ),
//             const SizedBox(height: 6),
//             Text(time, style: Apptexts.bodystyle.copyWith(color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }

//    // UPDATED: Sent message with enhanced status icon
//   Widget _buildSentMessage(
//     String text,
//     String time,
//     bool isRead,
//     bool isReceiverOnline,
//     String receiverId,
//   ) {
//     Size size = MediaQuery.of(context).size;
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Container(
//         constraints: BoxConstraints(maxWidth: size.width * 0.57),
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: const Color(0xff1565C0),
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(size.width * 0.05),
//             topRight: Radius.circular(size.width * 0.05),
//             bottomLeft: Radius.circular(size.width * 0.05),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               text,
//               style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
//             ),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   time,
//                   style: Apptexts.bodystyle.copyWith(color: Color(0xffE9EAEB)),
//                 ),
//                 const SizedBox(width: 5),
//                 _getMessageStatusIcon(true, isRead, isReceiverOnline, receiverId),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageInput(ChatProvider chatProvider, Size size) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//       color: const Color(0xff292929),
//       child: Row(
//         children: [
//           // Attachment button
//           GestureDetector(
//             onTap: () {
//               showModalBottomSheet(
//                 context: context,
//                 backgroundColor: Colors.transparent,
//                 builder: (context) {
//                   return _buildAttachmentBottomSheet();
//                 },
//               );
//             },
//             child: Container(
//               height: size.height * .05,
//               width: size.width * .1,
//               decoration: const BoxDecoration(
//                 color: Color(0xff3e3e3e),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(Icons.add, color: Color(0xff40C4FF), size: 28),
//             ),
//           ),
//           SizedBox(width: size.width * .02),
//           Expanded(
//             child:
//                 _isRecording
//                     ? _buildRecordingUI(size)
//                     : TextField(
//                       controller: _msgController,
//                       cursorColor: const Color(0xff40C4FF),
//                       style: const TextStyle(color: Colors.white),
//                       decoration: InputDecoration(
//                         hintText: "Type a message...",
//                         hintStyle: const TextStyle(color: Colors.white54),
//                         fillColor: const Color(0xff3e3e3e),
//                         filled: true,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                       onChanged: (value) {
//                         setState(() {});
//                       },
//                     ),
//           ),
//           SizedBox(width: size.width * .02),
//           Container(
//             height: size.height * .07,
//             width: size.width * .13,
//             decoration: const BoxDecoration(
//               color: Color(0xff40C4FF),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               onPressed: () async {
//                 if (_isRecording) {
//                   _stopRecording();
//                 } else if (_msgController.text.trim().isNotEmpty) {
//                   // FIXED: Check if message can be sent before sending
//                   await _handleSendMessage(chatProvider);
//                 } else {
//                   _startRecording();
//                 }
//               },
//               icon: Icon(
//                 _isRecording || _msgController.text.trim().isNotEmpty
//                     ? Icons.send
//                     : Icons.mic,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Optional: Add visual indicator when user is blocked
//   Widget _buildBlockedIndicator() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.red.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.block, color: Colors.red, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               'You cannot send messages to this user',
//               style: TextStyle(color: Colors.red, fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _handleSendMessage(ChatProvider chatProvider) async {
//     final messageText = _msgController.text.trim();
//     if (messageText.isEmpty) return;

//     try {
//       // Show sending indicator (optional)
//       // _showSendingIndicator();

//       await chatProvider.sendMessage(
//         senderId: currentUserId,
//         receiverId: widget.receiverId,
//         text: messageText,
//       );

//       _msgController.clear();
//     } catch (e) {
//       // Handle blocking or other errors
//       String errorMessage = 'Failed to send message';

//       if (e.toString().contains('blocked')) {
//         errorMessage =
//             'Cannot send message. User may have blocked you or you have blocked this user.';
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(errorMessage),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   Widget _buildAttachmentBottomSheet() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Color(0xff3e3e3e),
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 40,
//             height: 5,
//             decoration: BoxDecoration(
//               color: Colors.grey[600],
//               borderRadius: BorderRadius.circular(3),
//             ),
//           ),
//           SizedBox(height: MediaQuery.of(context).size.height * .04),
//           GridView.count(
//             shrinkWrap: true,
//             crossAxisCount: 3,
//             mainAxisSpacing: 10,
//             crossAxisSpacing: 15,

//             children: [
//               _buildAttachmentOption(
//                 Icons.camera_alt,
//                 "Camera",
//                 _pickImageFromCamera,
//               ),
//               _buildAttachmentOption(Icons.mic, "Record", () {
//                 Navigator.pop(context); // Close bottom sheet
//                 _startRecording();
//               }),
//               _buildAttachmentOption(Icons.contacts, "Contact", _pickContact),
//               _buildAttachmentOption(
//                 Icons.image,
//                 "Gallery",
//                 _pickImageFromGallery,
//               ),
//               _buildAttachmentOption(Icons.location_on, "Location", () {
//                 Navigator.pop(context);
//               }),
//               _buildAttachmentOption(
//                 Icons.insert_drive_file,
//                 "Document",
//                 _pickDocument,
//               ),
//             ],
//           ),
//           SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildAttachmentOption(
//     IconData icon,
//     String text,
//     VoidCallback onTap,
//   ) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircleAvatar(
//             radius: 22,
//             backgroundColor: Color(0xff40C4FF),
//             child: Icon(icon, size: 22, color: Colors.white),
//           ),
//           SizedBox(height: 8),
//           Text(text, style: const TextStyle(color: Colors.white)),
//         ],
//       ),
//     );
//   }
// }

// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/constants/image_view.dart';
import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/homepage.dart/contactdetail.dart';
import 'package:chat_app/model/chatmodel.dart';
import 'package:chat_app/state/chatstate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class Chatscreen extends StatefulWidget {
  final String name;
  final String image;
  final String receiverId;
  final String phone;
  final String senderId;
  const Chatscreen({
    super.key,
    required this.name,
    required this.image,
    required this.receiverId,
    required this.phone,
    required this.senderId,
  });

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // FIX: Get currentUserId safely
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  late Stream<Map<String, dynamic>> _receiverStatusStream;
  bool _isReceiverOnline = false;
  Timestamp? _receiverLastSeen;
  bool _isLoadingMessages = true;
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  String _currentPlayingUrl = '';
  bool _isUserBlocked = false;
  bool _hasBlockedReceiver = false;

  // Message selection
  final Set<String> _selectedMessages = {};
  bool _isSelecting = false;

  List<MessageModel> _currentMessages = [];
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  late String chatId;

  @override
  void initState() {
    super.initState();

    // ✅ Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // FIX: Initialize chatId properly
    chatId = getChatId(currentUserId, widget.receiverId);
    _initializeStatusStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
      _checkBlockingStatus();
    });

    _setUserOnlineStatus(true);
    _setupAudioPlayerListeners();
  }

  @override
  void dispose() {
    // ✅ Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _recordingTimer?.cancel();
    _setUserOnlineStatus(false);
    _msgController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // FIX: Proper message marking
  void _markMessagesAsRead() {
    if (chatId.isEmpty || currentUserId.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.markMessagesAsRead(chatId, currentUserId);
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _audioPosition = Duration.zero;
          _currentPlayingUrl = '';
        });
      }
    });
  }

  void _initializeStatusStream() {
    _receiverStatusStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return doc.data() as Map<String, dynamic>;
          }
          return {};
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeStatusStream();
  }

  Future<void> _setUserOnlineStatus(bool isOnline) async {
    try {
      if (currentUserId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
            'isOnline': isOnline,
            'lastSeen': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating online status: $e');
      }
    }
  }

  String getChatId(String user1, String user2) {
    if (user1.isEmpty || user2.isEmpty) return '';

    List<String> users = [user1, user2];
    users.sort();
    return "${users[0]}_${users[1]}";
  }

  String formatTimestamp(DateTime timestamp) {
    return DateFormat("hh:mm a").format(timestamp);
  }

  String formatLastSeen(Timestamp? lastSeen) {
    if (lastSeen == null) return "Offline";

    final now = DateTime.now();
    final seenTime = lastSeen.toDate();
    final difference = now.difference(seenTime);

    if (difference.inSeconds < 60) return "Last seen just now";
    if (difference.inMinutes < 60) {
      return "Last seen ${difference.inMinutes}m ago";
    }
    if (difference.inHours < 24) return "Last seen ${difference.inHours}h ago";
    if (difference.inDays < 7) return "Last seen ${difference.inDays}d ago";

    return "Last seen ${DateFormat("MMM dd, yyyy").format(seenTime)}";
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Message selection methods
  void _toggleMessageSelection(String? messageId) {
    // defensive: ignore null/empty ids
    if (messageId == null || messageId.isEmpty) return;

    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
      } else {
        _selectedMessages.add(messageId);
      }

      _isSelecting = _selectedMessages.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessages.clear();
      _isSelecting = false;
    });
  }

  Future<void> _deleteSelectedMessages({bool deleteForEveryone = false}) async {
    if (_selectedMessages.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final count = _selectedMessages.length;

    try {
      await chatProvider.deleteMultipleMessages(
        chatId,
        _selectedMessages.toList(),
        deleteForEveryone: deleteForEveryone,
        currentUserId: currentUserId,
      );

      _clearSelection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleteForEveryone
                ? 'Deleted for everyone'
                : 'Deleted $count message(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBlockingStatus();
      print('🔄 App resumed - rechecking block status');
    }
  }

  Future<void> _checkBlockingStatus() async {
    try {
      if (currentUserId.isEmpty) return;

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final hasBlocked = await chatProvider.isUserBlocked(widget.receiverId);
      final isBlockedByReceiver = await chatProvider.isBlockedByUser(
        widget.receiverId,
      );

      if (mounted) {
        setState(() {
          _hasBlockedReceiver = hasBlocked;
          _isUserBlocked = isBlockedByReceiver;
        });
      }
    } catch (e) {
      print('❌ Error checking block status: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Blocked input UI

  // Widget _buildBlockedInputUI(Size size) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  //     color: const Color(0xff292929),
  //     child: GestureDetector(
  //       onTap: _showUnblockDialog,
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(vertical: 14),
  //         decoration: BoxDecoration(
  //           color: const Color(0xff3e3e3e),
  //           borderRadius: BorderRadius.circular(10),
  //           border: Border.all(color: Colors.red.withOpacity(0.3)),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.block, color: Colors.red.withOpacity(0.8), size: 20),
  //             const SizedBox(width: 12),
  //             Text(
  //               'You blocked this contact. Tap to unblock',
  //               style: TextStyle(
  //                 color: Colors.red.withOpacity(0.9),
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _showUnblockDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xff3e3e3e),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Unblock ${widget.name}?',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: Text(
              'You will be able to send and receive messages from this contact again.',
              style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final chatProvider = Provider.of<ChatProvider>(
                      context,
                      listen: false,
                    );
                    await chatProvider.unblockUser(widget.receiverId);

                    setState(() {
                      _hasBlockedReceiver = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unblocked ${widget.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error unblocking: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'UNBLOCK',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/dchbirfkc/upload");
      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = 'chat_app'
            ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      print('Cloudinary upload status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final jsonMap = json.decode(resStr);
        print('Cloudinary response: $jsonMap');
        return jsonMap['secure_url'];
      } else {
        final errorResponse = await response.stream.bytesToString();
        print('Cloudinary error: $errorResponse');
        SnackbarMessage.failedsnack("Failed to upload file", context);
        return null;
      }
    } catch (e) {
      print('Cloudinary exception: $e');
      SnackbarMessage.failedsnack("Error uploading file: $e", context);
      return null;
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        _sendMediaMessage(File(image.path), 'image');
      }
    } catch (e) {
      SnackbarMessage.failedsnack('Error accessing camera: $e', context);
      print('Error accessing camera: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // ✅ Ask for permission
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        SnackbarMessage.failedsnack('Gallery access denied', context);
        return;
      }

      // ✅ Open gallery picker (supports multiple image/video)
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          requestType: RequestType.common, // image + video
          maxAssets: 10, // allow up to 10
          themeColor: Colors.blue,
        ),
      );

      if (assets == null || assets.isEmpty) return;

      for (final asset in assets) {
        final File? file = await asset.file;
        if (file == null) continue;

        final String type = (asset.type == AssetType.video) ? 'video' : 'image';

        _sendMediaMessage(file, type);
      }
    } catch (e) {
      SnackbarMessage.failedsnack('Error accessing gallery: $e', context);
      print('Error accessing gallery: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        _sendMediaMessage(File(result.files.single.path!), 'document');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking document: $e')));
      print('Error picking document: $e');
    }
  }

  Future<void> _openDocument(String documentUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(documentUrl));
      final tempDir = await getTemporaryDirectory();
      final extension = documentUrl.split('.').last.split('?').first;
      final file = File('${tempDir.path}/$fileName.$extension');
      await file.writeAsBytes(response.bodyBytes);

      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        throw 'Failed to open document: ${result.message}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () => _openDocument(documentUrl, fileName),
          ),
        ),
      );
    }
  }

  Widget _buildShimmerLoadingState() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(10),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor:
                    isMe
                        ? const Color(0xff1565C0).withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                highlightColor:
                    isMe
                        ? const Color(0xff1565C0).withOpacity(0.5)
                        : Colors.white.withOpacity(0.4),
                child: Container(
                  width: 200,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: filePath);

        _recordingDuration = Duration.zero;
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration += Duration(seconds: 1);
          });
        });

        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      SnackbarMessage.failedsnack('Error starting recording: $e', context);
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      if (path != null) {
        _sendMediaMessage(File(path), 'audio');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      SnackbarMessage.failedsnack('Error stopping recording: $e', context);
    }
  }

  Widget _buildRecordingUI(Size size) {
    final minutes = _recordingDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _recordingDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final durationText = '$minutes:$seconds';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xff3e3e3e),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _isRecording = false;
                _recordingTimer?.cancel();
                _recordingTimer = null;
                _recordingDuration = Duration.zero;
                _audioRecorder.stop();
              });
            },
          ),
          SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (index) {
                  final animationValue =
                      (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
                  final waveHeights = List.generate(12, (i) {
                    final baseHeight = 8 + (i % 3) * 4;
                    final animatedHeight =
                        baseHeight +
                        (sin(animationValue * 2 * pi + i * 0.5) * 6).toInt();
                    return animatedHeight.clamp(8.0, 20.0).toDouble();
                  });

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 3,
                    height: waveHeights[index],
                    decoration: BoxDecoration(
                      color: Color(0xff40C4FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            durationText,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.play_arrow, color: Colors.grey),
            onPressed: null,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAudioPlayback(String audioUrl) async {
    try {
      if (_currentPlayingUrl == audioUrl && _isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_isPlaying) {
          await _audioPlayer.stop();
        }
        await _audioPlayer.play(UrlSource(audioUrl));

        setState(() {
          _currentPlayingUrl = audioUrl;
          _isPlaying = true;
          _audioPosition = Duration.zero;
        });
        Future.delayed(Duration(milliseconds: 100), () async {
          final duration = await _audioPlayer.getDuration();
          if (mounted && duration != null) {
            setState(() {
              _audioDuration = duration;
            });
          }
        });
        _audioPlayer.onPositionChanged.listen((Duration position) {
          if (mounted) {
            setState(() {
              _audioPosition = position;
            });
          }
        });
        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _audioPosition = Duration.zero;
              _currentPlayingUrl = '';
            });
          }
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  List<Map<String, dynamic>> _getMediaMessages(List<MessageModel> messages) {
    return messages
        .where(
          (message) =>
              message.mediaUrl != null &&
              message.mediaUrl!.isNotEmpty &&
              (message.messageType == 'image' ||
                  message.messageType == 'video'),
        )
        .map(
          (message) => {
            'mediaUrl': message.mediaUrl,
            'text': message.text,
            'timestamp': message.timestamp,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _getLinkMessages(List<MessageModel> messages) {
    final urlRegex = RegExp(
      r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );

    return messages
        .where((message) => urlRegex.hasMatch(message.text))
        .map(
          (message) => {'text': message.text, 'timestamp': message.timestamp},
        )
        .toList();
  }

  List<Map<String, dynamic>> _getDocumentMessages(List<MessageModel> messages) {
    return messages
        .where((message) => message.messageType == 'document')
        .map(
          (message) => {
            'text': message.text,
            'mediaUrl': message.mediaUrl,
            'timestamp': message.timestamp,
          },
        )
        .toList();
  }

  Future<void> _pickContact() async {
    try {
      final status = await Permission.contacts.request();

      if (status.isGranted) {
        final Contact? contact = await FlutterContacts.openExternalPick();

        if (contact != null) {
          final chatProvider = Provider.of<ChatProvider>(
            context,
            listen: false,
          );
          final canSend = await chatProvider.canSendMessage(widget.receiverId);

          if (!canSend) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cannot share contact. User may have blocked you or you have blocked this user.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final contactInfo = {
            'name': contact.displayName,
            'phones': contact.phones.map((phone) => phone.number).toList(),
            'emails': contact.emails.map((email) => email.address).toList(),
          };

          await chatProvider.sendMessage(
            senderId: currentUserId,
            receiverId: widget.receiverId,
            text: '📞 Contact: ${contact.displayName}',
            messageType: 'contact',
            contactInfo: contactInfo,
          );
        }
      } else {
        SnackbarMessage.failedsnack('Contacts permission denied', context);
      }
    } catch (e) {
      String errorMessage = 'Error picking contact';
      if (e.toString().contains('blocked')) {
        errorMessage =
            'Cannot share contact. User may have blocked you or you have blocked this user.';
      }

      SnackbarMessage.failedsnack('$errorMessage: $e', context);
    }
  }

  Future<void> _sendMediaMessage(File file, String type) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      final canSend = await chatProvider.canSendMessage(widget.receiverId);
      if (!canSend) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot send media. User may have blocked you or you have blocked this user.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      final uploadedUrl = await _uploadToCloudinary(file);
      Navigator.pop(context);

      if (uploadedUrl != null) {
        String text = '';
        switch (type) {
          case 'image':
            text = '📷 Image';
            break;
          case 'video':
            text = '🎥 Video';
            break;
          case 'document':
            text = '📄 Document';
            break;
          case 'audio':
            text = '🎤 Voice message';
            break;
        }

        await chatProvider.sendMessage(
          senderId: currentUserId,
          receiverId: widget.receiverId,
          text: text,
          mediaUrl: uploadedUrl,
          messageType: type,
        );
      }
    } catch (e) {
      Navigator.pop(context);

      String errorMessage = 'Error sending media';
      if (e.toString().contains('blocked')) {
        errorMessage =
            'Cannot send media. User may have blocked you or you have blocked this user.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UPDATED: Message status icon with single tick for blocked users
  Widget _getMessageStatusIcon(
    bool delivered,
    bool isRead,
    bool isReceiverOnline,
  ) {
    if (!delivered) {
      return Icon(Icons.check, size: 16, color: Colors.grey); // single tick
    }
    if (delivered && !isRead) {
      return Icon(Icons.done_all, size: 16, color: Colors.grey); // double tick
    }
    if (isRead) {
      return Icon(
        Icons.done_all,
        size: 16,
        color: Colors.blue,
      ); // blue double tick
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff2c2d3a),
        body: Column(
          children: [
            // Header
            StreamBuilder<Map<String, dynamic>>(
              stream: _receiverStatusStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  _isReceiverOnline = data['isOnline'] ?? false;
                  _receiverLastSeen = data['lastSeen'] as Timestamp?;
                }

                final statusText =
                    _isReceiverOnline
                        ? "Online"
                        : formatLastSeen(_receiverLastSeen);

                return Container(
                  height: size.height * .1,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xff292929)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap:
                              _isSelecting
                                  ? _clearSelection
                                  : () => Navigator.pop(context),
                          child: Container(
                            height: size.height * .05,
                            width: size.width * .1,
                            decoration: const BoxDecoration(
                              color: Color(0xff3e3e3e),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isSelecting ? Icons.close : Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * .02),
                        if (!_isSelecting) ...[
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundImage:
                                    widget.image.startsWith("http")
                                        ? NetworkImage(widget.image)
                                        : AssetImage(widget.image)
                                            as ImageProvider,
                              ),
                              if (_isReceiverOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        SizedBox(width: size.width * .03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSelecting
                                    ? '${_selectedMessages.length} selected'
                                    : widget.name,
                                softWrap: true,
                                style: Apptexts.titlestyle.copyWith(
                                  color: Colors.white,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!_isSelecting)
                                Text(
                                  statusText,
                                  style: Apptexts.bodystyle.copyWith(
                                    color:
                                        _isReceiverOnline
                                            ? Colors.green
                                            : Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_isSelecting) ...[
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final deleteForEveryone = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      backgroundColor: const Color(0xff2c2d3a),
                                      title: const Text(
                                        "Delete message",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        "Do you want to delete for everyone or just for you?",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(
                                                context,
                                                false,
                                              ), // Delete for me
                                          child: const Text("Delete for me"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(
                                                context,
                                                true,
                                              ), // Delete for everyone
                                          child: const Text(
                                            "Delete for everyone",
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              // 🚨 If user presses back (null), DO NOTHING
                              if (deleteForEveryone == null) {
                                return; // just close dialog, keep messages selected
                              }

                              // ✅ Only call delete if user actually chose something
                              await _deleteSelectedMessages(
                                deleteForEveryone: deleteForEveryone,
                              );
                            },
                          ),
                        ] else ...[
                          SizedBox(width: size.width * .02),
                          Image.asset(
                            "assets/images/video.png",
                            height: size.height * .06,
                            width: size.width * .12,
                          ),
                          SizedBox(width: size.width * .015),
                          GestureDetector(
                            onTap: () {},
                            child: Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          SizedBox(width: size.width * .015),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (
                                        context,
                                      ) => StreamBuilder<List<MessageModel>>(
                                        stream: chatProvider.getMessagesStream(
                                          currentUserId,
                                          chatId,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            _currentMessages = snapshot.data!;
                                            return ContactInfoScreen(
                                              contactName: widget.name,
                                              contactPhone: widget.phone,
                                              contactImageUrl: widget.image,
                                              chatId: chatId,
                                              currentUserId: currentUserId,
                                              mediaMessages: _getMediaMessages(
                                                _currentMessages,
                                              ),
                                              linkMessages: _getLinkMessages(
                                                _currentMessages,
                                              ),
                                              documentMessages:
                                                  _getDocumentMessages(
                                                    _currentMessages,
                                                  ),
                                            );
                                          }
                                          return Scaffold(
                                            backgroundColor: const Color(
                                              0xff292929,
                                            ),
                                            body: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                      ),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // Messages area
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatProvider.getMessagesStream(chatId, currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _isLoadingMessages) {
                    return _buildShimmerLoadingState();
                  }

                  if (snapshot.hasError) {
                    _isLoadingMessages = false;
                    return _buildShimmerLoadingState();
                  }

                  final messages = snapshot.data ?? [];
                  _currentMessages = messages;

                  if (messages.isEmpty && !_isLoadingMessages) {
                    return Center(
                      child: Text(
                        "No messages yet",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];

                      // Get a stable id for each message — try common fields, fallback to doc timestamp
                      final rawId = message.messageId ?? message.id;
                      final msgId = rawId.toString(); // ensure String

                      final isMe = message.senderId == currentUserId;
                      final time = formatTimestamp(message.timestamp);
                      final isSelected =
                          // ignore: unnecessary_null_comparison
                          msgId != null && _selectedMessages.contains(msgId);

                      Widget messageWidget;
                      if (message.mediaUrl != null &&
                          message.mediaUrl!.isNotEmpty) {
                        messageWidget = _buildMediaMessage(message, isMe, time);
                      } else if (message.messageType == 'contact') {
                        messageWidget = _buildContactMessage(
                          message,
                          isMe,
                          time,
                        );
                      } else {
                        messageWidget =
                            isMe
                                ? _buildSentMessage(
                                  message.text,
                                  time,
                                  message.isRead,
                                  _isReceiverOnline,
                                )
                                : _buildReceivedMessage(message.text, time);
                      }

                      return GestureDetector(
                        behavior:
                            HitTestBehavior.opaque, // make entire area hittable
                        onLongPress: () {
                          // debug
                          // print('Long press on msgId: $msgId');
                          _toggleMessageSelection(msgId);
                        },
                        onTap:
                            _isSelecting
                                ? () => _toggleMessageSelection(msgId)
                                : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isSelecting)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 8.0,
                                  top: 4.0,
                                ),
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) {
                                    setState(() {
                                      _toggleMessageSelection(msgId);
                                    });
                                  },
                                  activeColor: Colors.blue,
                                  checkColor: Colors.white,
                                ),
                              ),
                            Expanded(child: messageWidget),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(color: Color(0xff595a6d), height: 1),

            // Conditional input based on block status
            _hasBlockedReceiver
                ? _buildBlockedInputUI(size, _hasBlockedReceiver)
                : _buildMessageInput(chatProvider, size),
          ],
        ),
      ),
    );
  }

  // NEW: Selection header widget
  // Widget _buildSelectionHeader(Size size) {
  //   return Container(
  //     height: size.height * .08,
  //     width: double.infinity,
  //     decoration: const BoxDecoration(color: Color(0xff292929)),
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: Row(
  //         children: [
  //           IconButton(
  //             icon: Icon(Icons.delete, color: Colors.red),
  //             onPressed: () async {
  //               final deleteForEveryone =
  //                   await showDialog<bool>(
  //                     context: context,
  //                     builder:
  //                         (context) => AlertDialog(
  //                           backgroundColor: Color(0xff2c2d3a),
  //                           title: Text(
  //                             "Delete message",
  //                             style: TextStyle(color: Colors.white),
  //                           ),
  //                           content: Text(
  //                             "Do you want to delete for everyone or just for you?",
  //                             style: TextStyle(color: Colors.white70),
  //                           ),
  //                           actions: [
  //                             TextButton(
  //                               onPressed: () => Navigator.pop(context, false),
  //                               child: Text("Delete for me"),
  //                             ),
  //                             TextButton(
  //                               onPressed: () => Navigator.pop(context, true),
  //                               child: Text("Delete for everyone"),
  //                             ),
  //                           ],
  //                         ),
  //                   ) ??
  //                   false;

  //               await _deleteSelectedMessages(
  //                 deleteForEveryone: deleteForEveryone,
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  String _getVideoThumbnailUrl(String videoUrl) {
    if (videoUrl.contains('cloudinary.com')) {
      // Enhanced transformation for better thumbnails
      return videoUrl.replaceFirst(
        '/upload/',
        '/upload/w_400,h_300,c_fill,so_0,eo_0.1,q_auto:best,f_jpg/',
      );
    }
    return videoUrl;
  }

  Widget _buildMediaMessage(MessageModel message, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isMe ? Color(0xff1565C0) : Colors.grey.shade400,
            width: 5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(07),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * .57,
            ),
            color: isMe ? Color(0xff1565C0) : Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.messageType == 'image' ||
                    message.messageType == 'video')
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FullScreenMediaViewer(
                                  mediaUrl: message.mediaUrl!,
                                  heroTag: message.mediaUrl!,
                                ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          Hero(
                            tag: message.mediaUrl!,
                            child: CachedNetworkImage(
                              imageUrl:
                                  message.messageType == 'video'
                                      ? _getVideoThumbnailUrl(message.mediaUrl!)
                                      : message.mediaUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: Colors.white,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        message.messageType == 'video'
                                            ? Icons.videocam_off
                                            : Icons.broken_image,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                              memCacheHeight: 400,
                              memCacheWidth: 400,
                            ),
                          ),
                          // Add play button overlay for videos
                          if (message.messageType == 'video')
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.3),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else if (message.messageType == 'audio')
                  _buildAudioPlayerForMedia(message.mediaUrl!, isMe, time)
                else if (message.messageType == 'document')
                  GestureDetector(
                    onTap:
                        () => _openDocument(
                          message.mediaUrl!,
                          _getDocumentName(message.text),
                        ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * .57,
                        maxHeight: 65,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getDocumentIcon(message.mediaUrl),
                              size: 28,
                              color: isMe ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getDocumentName(message.text),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap to open',
                                  style: TextStyle(
                                    color:
                                        isMe
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (message.messageType != 'audio')
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                      bottom: 6,
                      top: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color:
                                isMe
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) const SizedBox(width: 5),
                        if (isMe)
                          _getMessageStatusIcon(
                            true,
                            message.isRead,
                            _isReceiverOnline,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayerForMedia(String audioUrl, bool isMe, String time) {
    final bool isCurrentlyPlaying =
        _currentPlayingUrl == audioUrl && _isPlaying;
    final Duration position =
        isCurrentlyPlaying ? _audioPosition : Duration.zero;

    final String durationText =
        isCurrentlyPlaying
            ? '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}'
            : '0:00';

    final double progress =
        _audioDuration.inMilliseconds > 0
            ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _toggleAudioPlayback(audioUrl),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isMe
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xff1565C0).withOpacity(0.1),
                  ),
                  child: Icon(
                    isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                    color: isMe ? Colors.white : const Color(0xff1565C0),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(15, (index) {
                          final heights = [
                            6,
                            10,
                            14,
                            18,
                            16,
                            12,
                            8,
                            6,
                            10,
                            14,
                            18,
                            12,
                            8,
                            10,
                            6,
                          ];
                          return Container(
                            width: 3,
                            height: heights[index % heights.length].toDouble(),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                      if (isCurrentlyPlaying || progress > 0)
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(15, (index) {
                                final heights = [
                                  6,
                                  10,
                                  14,
                                  18,
                                  16,
                                  12,
                                  8,
                                  6,
                                  10,
                                  14,
                                  18,
                                  12,
                                  8,
                                  10,
                                  6,
                                ];
                                return Container(
                                  width: 3,
                                  height:
                                      heights[index % heights.length]
                                          .toDouble(),
                                  decoration: BoxDecoration(
                                    color:
                                        isMe
                                            ? Colors.white
                                            : const Color(0xff1565C0),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                durationText,
                style: TextStyle(
                  color:
                      isMe ? Colors.white.withOpacity(0.9) : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color:
                      isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                  fontSize: 10,
                ),
              ),
              if (isMe) const SizedBox(width: 5),
              if (isMe) _getMessageStatusIcon(true, true, _isReceiverOnline),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String? mediaUrl) {
    if (mediaUrl == null) return Icons.insert_drive_file;

    final extension = mediaUrl.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_fields;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getDocumentName(String? text) {
    if (text == null || text.isEmpty) return 'Document';
    if (text.startsWith('📄 Document')) return 'Document';
    return text;
  }

  Widget _buildContactMessage(MessageModel message, bool isMe, String time) {
    final contactInfo = message.contactInfo ?? {};
    final contactName = contactInfo['name'] ?? 'Unknown';
    final phones = contactInfo['phones'] ?? [];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xff1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone,
                  color: isMe ? Colors.white : Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  'Contact: $contactName',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (phones.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Phone: ${phones.first}',
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (isMe) SizedBox(width: 5),
                if (isMe)
                  _getMessageStatusIcon(
                    true,
                    message.isRead,
                    _isReceiverOnline,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage(String text, String time) {
    Size size = MediaQuery.of(context).size;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        constraints: BoxConstraints(maxWidth: size.width * 0.57),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size.width * 0.05),
            topRight: Radius.circular(size.width * 0.05),
            bottomRight: Radius.circular(size.width * 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Apptexts.subtitlestyle.copyWith(color: Color(0xff2C2D3A)),
            ),
            const SizedBox(height: 6),
            Text(time, style: Apptexts.bodystyle.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSentMessage(
    String text,
    String time,
    bool isRead,
    bool isReceiverOnline,
  ) {
    Size size = MediaQuery.of(context).size;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: size.width * 0.57),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff1565C0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size.width * 0.05),
            topRight: Radius.circular(size.width * 0.05),
            bottomLeft: Radius.circular(size.width * 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: Apptexts.bodystyle.copyWith(color: Color(0xffE9EAEB)),
                ),
                const SizedBox(width: 5),
                _getMessageStatusIcon(true, isRead, isReceiverOnline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider, Size size) {
    // ✅ If either party has blocked the other, show appropriate UI
    if (_hasBlockedReceiver || _isUserBlocked) {
      return _buildBlockedInputUI(size, _hasBlockedReceiver);
    }

    return _normalInput(chatProvider, size);
  }

  Widget _buildBlockedInputUI(Size size, bool iDidTheBlocking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: const Color(0xff292929),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xff3e3e3e),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, color: Colors.red.withOpacity(0.8), size: 20),
            const SizedBox(width: 12),
            Text(
              iDidTheBlocking
                  ? 'You blocked this contact. Tap to unblock'
                  : 'This contact has blocked you',
              style: TextStyle(
                color: Colors.red.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _normalInput(ChatProvider chatProvider, Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      color: const Color(0xff292929),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return _buildAttachmentBottomSheet();
                },
              );
            },
            child: Container(
              height: size.height * .05,
              width: size.width * .1,
              decoration: const BoxDecoration(
                color: Color(0xff3e3e3e),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: Color(0xff40C4FF), size: 28),
            ),
          ),
          SizedBox(width: size.width * .02),
          Expanded(
            child:
                _isRecording
                    ? _buildRecordingUI(size)
                    : TextField(
                      controller: _msgController,
                      cursorColor: const Color(0xff40C4FF),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        fillColor: const Color(0xff3e3e3e),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
          ),
          SizedBox(width: size.width * .02),
          Container(
            height: size.height * .07,
            width: size.width * .13,
            decoration: const BoxDecoration(
              color: Color(0xff40C4FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                if (_isRecording) {
                  _stopRecording();
                } else if (_msgController.text.trim().isNotEmpty) {
                  await _handleSendMessage(chatProvider);
                } else {
                  _startRecording();
                }
              },
              icon: Icon(
                _isRecording || _msgController.text.trim().isNotEmpty
                    ? Icons.send
                    : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage(ChatProvider chatProvider) async {
    final messageText = _msgController.text.trim();
    if (messageText.isEmpty) return;

    // ✅ Clear the text field immediately for better UX
    _msgController.clear();

    try {
      await chatProvider.sendMessage(
        senderId: currentUserId,
        receiverId: widget.receiverId,
        text: messageText,
      );

      print('✅ Message sent successfully');
    } catch (e) {
      // ✅ Restore the message text if send failed
      _msgController.text = messageText;

      String errorMessage = 'Failed to send message';

      if (e.toString().contains('blocked')) {
        errorMessage =
            'You have blocked this contact. Unblock to send messages.';

        // ✅ Trigger block status refresh
        _checkBlockingStatus();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action:
                e.toString().contains('blocked')
                    ? SnackBarAction(
                      label: 'UNBLOCK',
                      textColor: Colors.white,
                      onPressed: _showUnblockDialog,
                    )
                    : null,
          ),
        );
      }
    }
  }

  Widget _buildAttachmentBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xff3e3e3e),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * .04),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 15,
            children: [
              _buildAttachmentOption(
                Icons.camera_alt,
                "Camera",
                _pickImageFromCamera,
              ),
              _buildAttachmentOption(Icons.mic, "Record", () {
                Navigator.pop(context);
                _startRecording();
              }),
              _buildAttachmentOption(Icons.contacts, "Contact", _pickContact),
              _buildAttachmentOption(
                Icons.image,
                "Gallery",
                _pickImageFromGallery,
              ),
              _buildAttachmentOption(Icons.location_on, "Location", () {
                Navigator.pop(context);
              }),
              _buildAttachmentOption(
                Icons.insert_drive_file,
                "Document",
                _pickDocument,
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xff40C4FF),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
