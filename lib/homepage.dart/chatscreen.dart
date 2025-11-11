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
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher.dart';
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
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  String _currentPlayingUrl = '';
  bool _isUserBlocked = false;
  bool _hasBlockedReceiver = false;
  List<MessageModel> _cachedMessages = [];
  bool _hasCachedMessages = false;
  Stream<List<MessageModel>>? _cachedMessageStream;
  bool _isInitialBlockCheckDone = false;
  bool _isBlockCheckInProgress = false;
  DateTime? _lastBlockCheckTime;

  // Message selection
  final Set<String> _selectedMessages = {};
  bool _isSelecting = false;

  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  late String chatId;

  @override
  void initState() {
    super.initState();

    // ✅ Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    chatId = getChatId(currentUserId, widget.receiverId);
    _initializeStatusStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
      if (!_isInitialBlockCheckDone) {
        _checkBlockingStatus();
        _isInitialBlockCheckDone = true;
      }
    });

    _setUserOnlineStatus(true);
    _setupAudioPlayerListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _recordingTimer?.cancel();
    _setUserOnlineStatus(false);
    _msgController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Stream<List<MessageModel>> _getMessageStream(ChatProvider chatProvider) {
    _cachedMessageStream ??=
        chatProvider
            .getMessagesStream(chatId, currentUserId)
            .asBroadcastStream();
    return _cachedMessageStream!;
  }

  // ✅ ADD: Try to get cached messages first
  void _loadInitialMessages(ChatProvider chatProvider) {
    // Try to get cached messages first
    final cachedMessages = chatProvider.getCachedMessages(chatId);
    if (cachedMessages != null && cachedMessages.isNotEmpty) {
      setState(() {
        _cachedMessages = cachedMessages;
        _hasCachedMessages = true;
      });
    }
  }

  Future<void> _checkBlockingStatus() async {
    // ✅ Prevent multiple simultaneous checks
    if (_isBlockCheckInProgress) return;

    // ✅ Cache: Only check every 2 seconds max
    final now = DateTime.now();
    if (_lastBlockCheckTime != null &&
        now.difference(_lastBlockCheckTime!).inSeconds < 2) {
      return;
    }

    try {
      _isBlockCheckInProgress = true;

      if (currentUserId.isEmpty) return;

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // ✅ Use Future.wait to check both statuses simultaneously
      final results = await Future.wait([
        chatProvider.isUserBlocked(widget.receiverId),
        chatProvider.isBlockedByUser(widget.receiverId),
      ]);

      if (mounted) {
        setState(() {
          _hasBlockedReceiver = results[0];
          _isUserBlocked = results[1];
          _lastBlockCheckTime = DateTime.now();
        });
        print(
          '✅ Block status - You blocked: $_hasBlockedReceiver, Blocked by user: $_isUserBlocked',
        );
      }
    } catch (e) {
      print('❌ Error checking block status: $e');
    } finally {
      _isBlockCheckInProgress = false;
    }
  }

  @override
  void didUpdateWidget(Chatscreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Reset cache if receiver changed
    if (oldWidget.receiverId != widget.receiverId) {
      _cachedMessageStream = null;
      _cachedMessages.clear();
      _hasCachedMessages = false;
    }
  }

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
                    print('✅ Unblocked user: ${widget.receiverId}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unblocked ${widget.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('❌ Error unblocking user: $e');
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
      // Ask for permission
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        SnackbarMessage.failedsnack('Gallery access denied', context);
        return;
      }

      // Open gallery picker (supports multiple image/video)
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

  // Add these helper functions to your chat screenimport 'package:url_launcher/url_launcher.dart';

  bool _containsUrl(String text) {
    final urlRegex = RegExp(
      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(text);
  }

  String? _extractFirstUrl(String text) {
    final urlRegex = RegExp(
      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  String _extractDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.host}${uri.path}';
    } catch (e) {
      return url.length > 30 ? '${url.substring(0, 30)}...' : url;
    }
  }

  Widget _buildLinkMessage(String fullText, String url, bool isMe) {
    // Use the improved validation
    final bool isValidUrl = _isValidUrl(url);
    final displayUrl = _extractDisplayUrl(url);

    return GestureDetector(
      onTap: isValidUrl ? () => _launchUrl(url) : null,
      child: Container(
        decoration: BoxDecoration(
          color:
              isMe
                  ? Colors.white.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isMe
                    ? Colors.white.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL preview
            Row(
              children: [
                Icon(
                  Icons.link,
                  color:
                      isValidUrl
                          ? (isMe ? Colors.white : Colors.blue)
                          : Colors.grey,
                  size: 16,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayUrl,
                    style: TextStyle(
                      color:
                          isValidUrl
                              ? (isMe ? Colors.white : Colors.blue)
                              : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            // Full message text
            Text(
              fullText,
              style: TextStyle(
                color: isMe ? Colors.white : Color(0xff2C2D3A),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            // Click hint
            Text(
              isValidUrl ? 'Tap to open link' : 'Invalid URL format',
              style: TextStyle(
                color:
                    isValidUrl
                        ? (isMe ? Colors.white.withOpacity(0.7) : Colors.grey)
                        : Colors.orange,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this validation function
  bool _isValidUrl(String url) {
    try {
      if (url.isEmpty) return false;

      // Clean the URL first
      String cleanUrl = url.trim();

      // Add scheme if missing
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      // Try parsing
      final uri = Uri.parse(cleanUrl);

      // Basic validation
      return uri.host.isNotEmpty &&
          (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('❌ URL validation failed for "$url": $e');
      return false;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      print('🔄 Attempting to launch URL: $urlString');

      // Clean and validate URL first
      String formattedUrl = urlString.trim();

      // Remove any unwanted characters that might be at the end
      formattedUrl = formattedUrl.replaceAll(RegExp(r'[.,!?;:]$'), '');

      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }

      final Uri url = Uri.parse(formattedUrl);

      print('📱 Parsed URL: $url');
      print('📱 URL Scheme: ${url.scheme}');
      print('📱 URL Host: ${url.host}');
      print('📱 URL Path: ${url.path}');

      // Check if URL can be launched with better error handling
      bool canLaunch = false;
      try {
        canLaunch = await canLaunchUrl(url);
      } catch (e) {
        print('❌ canLaunchUrl error: $e');
        canLaunch = false;
      }

      print('🔍 Can launch URL: $canLaunch');

      if (canLaunch) {
        print('🚀 Launching URL...');
        final result = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableDomStorage: true,
            enableJavaScript: true,
          ),
        );

        print('✅ URL launch result: $result');

        if (!result) {
          throw Exception('launchUrl returned false');
        }
      } else {
        print('❌ Cannot launch URL - showing fallback options');

        // Show more helpful error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cannot open: ${url.host}'),
                Text(
                  'Try copying the URL instead',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL copied to clipboard'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('💥 URL Launch Error: $e');
      print('📝 Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open URL'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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

    return messages.where((message) => urlRegex.hasMatch(message.text)).map((
      message,
    ) {
      // Extract the first URL from the message
      final match = urlRegex.firstMatch(message.text);
      final url = match?.group(0) ?? '';

      return {
        'text': message.text,
        'url': url, // Make sure this is included
        'timestamp': message.timestamp,
      };
    }).toList();
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
    bool isUserBlocked, // Add this parameter
  ) {
    // ✅ If they blocked you, show single tick only
    if (isUserBlocked) {
      return Icon(Icons.check, size: 16, color: Colors.grey); // single tick
    }

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
                              // Get messages from cache/provider without StreamBuilder
                              final currentMessages = chatProvider
                                  .getCachedMessages(chatId);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ContactInfoScreen(
                                        contactName: widget.name,
                                        contactPhone: widget.phone,
                                        contactImageUrl: widget.image,
                                        chatId: chatId,
                                        currentUserId: currentUserId,
                                        receiverId: widget.receiverId,
                                        mediaMessages: _getMediaMessages(
                                          currentMessages!,
                                        ),
                                        linkMessages: _getLinkMessages(
                                          currentMessages,
                                        ),
                                        documentMessages: _getDocumentMessages(
                                          currentMessages,
                                        ),
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
            // Messages area - FIXED VERSION:
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _getMessageStream(chatProvider),
                builder: (context, snapshot) {
                  // ✅ Load initial cached messages
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !_hasCachedMessages) {
                      _loadInitialMessages(chatProvider);
                    }
                  });

                  // ✅ OPTIMIZED: Show cached data immediately
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    if (_hasCachedMessages && _cachedMessages.isNotEmpty) {
                      return _buildMessagesList(_cachedMessages);
                    }
                    return _buildShimmerLoadingState();
                  }

                  if (snapshot.hasError) {
                    if (_hasCachedMessages && _cachedMessages.isNotEmpty) {
                      return _buildMessagesList(_cachedMessages);
                    }
                    return _buildShimmerLoadingState();
                  }

                  final messages = snapshot.data ?? [];

                  // ✅ UPDATE CACHE and loading state
                  if (messages.isNotEmpty) {
                    _cachedMessages = messages;
                    _hasCachedMessages = true;
                    // _buildShimmerLoadingState = false;
                  }

                  if (messages.isEmpty && !_hasCachedMessages) {
                    return Center(
                      child: Text(
                        "No messages yet",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  // ✅ Use cached messages if no new messages
                  final messagesToDisplay =
                      messages.isNotEmpty ? messages : _cachedMessages;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients &&
                        messagesToDisplay.isNotEmpty) {
                      _scrollToBottom();
                    }
                  });

                  //       return _buildMessagesList(messagesToDisplay);
                  //     },
                  //   ),
                  // ),

                  //   return _buildMessagesList(messages);
                  // },

                  // // ✅ Show cached messages if no new messages
                  // if (messages.isEmpty && _hasCachedMessages) {
                  //   return _buildMessagesList(_cachedMessages);
                  // }

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
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () {
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

  // ✅ ADD THIS MISSING METHOD:
  Widget _buildMessagesList(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.all(10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];

        // Get a stable id for each message
        final rawId = message.messageId ?? message.id;
        final msgId = rawId.toString();

        final isMe = message.senderId == currentUserId;
        final time = formatTimestamp(message.timestamp);
        final isSelected = _selectedMessages.contains(msgId);

        Widget messageWidget;
        if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
          messageWidget = _buildMediaMessage(message, isMe, time);
        } else if (message.messageType == 'contact') {
          messageWidget = _buildContactMessage(message, isMe, time);
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
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            _toggleMessageSelection(msgId);
          },
          onTap: _isSelecting ? () => _toggleMessageSelection(msgId) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 4.0),
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
  }

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
                            _isUserBlocked,
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
              if (isMe)
                _getMessageStatusIcon(
                  true,
                  true,
                  _isReceiverOnline,
                  _isUserBlocked,
                ),
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
                    _isUserBlocked,
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
    final bool hasUrl = _containsUrl(text);
    final String? url = _extractFirstUrl(text);

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
            hasUrl && url != null
                ? _buildLinkMessage(text, url, false)
                : Text(
                  text,
                  style: Apptexts.subtitlestyle.copyWith(
                    color: Color(0xff2C2D3A),
                  ),
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
    final bool hasUrl = _containsUrl(text);
    final String? url = _extractFirstUrl(text);

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
            hasUrl && url != null
                ? _buildLinkMessage(text, url, true)
                : Text(
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
                _getMessageStatusIcon(
                  true,
                  isRead,
                  isReceiverOnline,
                  _isUserBlocked,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider, Size size) {
    // ✅ Only hide input if YOU blocked them
    if (_hasBlockedReceiver) {
      return _buildBlockedInputUI(size, _hasBlockedReceiver);
    }

    // ✅ If they blocked you, show normal input but with warning
    if (_isUserBlocked) {
      return Column(
        children: [
          // Warning message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xff292929),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You can't send messages to this contact. They may have blocked you.",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Still show input field
          _normalInput(chatProvider, size),
        ],
      );
    }

    // ✅ Normal case - no blocking
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
            GestureDetector(
              onTap: iDidTheBlocking ? _showUnblockDialog : null,
              child: Text(
                'You blocked this contact. Tap to unblock',

                style: TextStyle(
                  color: Colors.red.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
        print('⚠️ Send failed: User is blocked');

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
