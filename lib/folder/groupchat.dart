import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:chat_app/constants/image_view.dart';
import 'package:chat_app/folder/groupinfoscreen.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:chat_app/state/groupstate.dart';
import 'package:chat_app/model/groupmessagemodel.dart';
import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupImage;
  final int? memberCount;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupImage,
    this.memberCount,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Recording state
  bool _isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  String? _currentAudioPath;
  AnimationController? _recordingAnimationController;
  Animation<double>? _recordingAnimation;
  bool _isSelecting = false;
  final Set<String> _selectedMessages = {};
  bool _isPlaying = false;
  String _currentPlayingUrl = '';
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  bool _isNearBottom = true;
  // NEW: User data cache to avoid showing "Unknown User"
  final Map<String, String> _userNameCache = {};
  final Map<String, StreamSubscription> _userSubscriptions = {};
  bool _messagesMarkedAsRead = false;
  final Map<String, String> _userPhotoCache = {};
  List<GroupMessageModel>? _cachedMessages;
  // ✅ ADD: Cache for messages (same as chat screen)
  bool _hasCachedMessages = false;
  Stream<List<GroupMessageModel>>? _cachedMessageStream;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for recording
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _recordingAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    _setupAudioListeners();
    _setupScrollListener();
    _setUserOnlineStatus(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final groupProvider = Provider.of<GroupProvider>(
          context,
          listen: false,
        );
        groupProvider.markGroupMessagesAsRead(widget.groupId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Preload messages if not already cached
    if (!_hasCachedMessages) {
      _loadInitialMessages();
    }
  }

  // ✅ ADD: Load initial messages with caching (same pattern as chat screen)
  void _loadInitialMessages() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    // Try to get cached messages first
    final cachedMessages = groupProvider.getCachedGroupMessages(widget.groupId);
    if (cachedMessages != null && cachedMessages.isNotEmpty) {
      setState(() {
        _cachedMessages = cachedMessages;
        _hasCachedMessages = true;
      });
    }
  }

  // ✅ ADD: Get message stream with caching (same pattern as chat screen)
  Stream<List<GroupMessageModel>> _getMessageStream(
    GroupProvider groupProvider,
  ) {
    _cachedMessageStream ??=
        groupProvider.getGroupMessages(widget.groupId).asBroadcastStream();
    return _cachedMessageStream!;
  }

  // ✅ FIXED: Safe method to mark messages as read
  void _markMessagesAsRead() {
    if (_messagesMarkedAsRead || !mounted) return;

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.markGroupMessagesAsRead(widget.groupId);
      _messagesMarkedAsRead = true;
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _setUserOnlineStatus(bool isOnline) {
    try {
      FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("presence update error: $e");
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _audioPosition = Duration.zero;
          _currentPlayingUrl = '';
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _audioPosition = position);
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final position = _scrollController.position;
      setState(() {
        _isNearBottom = position.pixels <= 100;
      });
    });
  }

  @override
  void dispose() {
    didChangeAppLifecycleState(AppLifecycleState.inactive);

    // Cancel all user subscriptions
    _userSubscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    _userSubscriptions.clear();

    _recordingTimer?.cancel();
    _recordingAnimationController?.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _setUserOnlineStatus(false);
    _msgController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh cache when app resumes
      _markMessagesAsRead();
    }
  }

  String formatTime(dynamic timestamp) {
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      dateTime = DateTime.now();
    }
    return DateFormat("hh:mm a").format(dateTime);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Voice Recording Methods
  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        SnackbarMessage.failedsnack('Microphone permission required', context);
        return;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${tempDir.path}/$fileName';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _currentAudioPath = filePath;
      });

      // Start animation
      _recordingAnimationController?.repeat(reverse: true);

      // Start timer
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        }
      });
    } catch (e) {
      _handleError('starting recording', e);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      _recordingTimer?.cancel();
      _recordingAnimationController?.stop();
      _recordingAnimationController?.reset();

      setState(() {
        _isRecording = false;
      });

      if (path != null && _recordingDuration.inSeconds >= 1) {
        // Send the audio file
        await _sendGroupMedia(File(path), 'audio');
      } else {
        SnackbarMessage.failedsnack('Recording too short', context);
      }

      setState(() {
        _recordingDuration = Duration.zero;
        _currentAudioPath = null;
      });
    } catch (e) {
      _handleError('stopping recording', e);
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      _recordingTimer?.cancel();
      _recordingAnimationController?.stop();
      _recordingAnimationController?.reset();

      // Delete the recorded file
      if (_currentAudioPath != null) {
        final file = File(_currentAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _currentAudioPath = null;
      });
    } catch (e) {
      _handleError('canceling recording', e);
    }
  }

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
        SnackbarMessage.failedsnack("Failed to upload file", context);
        return null;
      }
    } catch (e) {
      print('Cloudinary exception: $e');
      SnackbarMessage.failedsnack("Error uploading file: $e", context);
      return null;
    }
  }

  Future<bool> _validateFile(File file, String type) async {
    final size = await file.length();
    final maxSize = type == 'image' ? 10 * 1024 * 1024 : 25 * 1024 * 1024;

    if (size > maxSize) {
      SnackbarMessage.failedsnack(
        'File is too large. Maximum size: ${maxSize ~/ (1024 * 1024)}MB',
        context,
      );
      return false;
    }
    return true;
  }

  void _handleError(String operation, dynamic error) {
    print('$operation error: $error');
    if (mounted) {
      SnackbarMessage.failedsnack(
        'Error during $operation: ${error.toString()}',
        context,
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // ✅ Step 1: Ask for permission according to Android version
      if (Platform.isAndroid) {
        if (await Permission.photos.isDenied ||
            await Permission.videos.isDenied ||
            await Permission.storage.isDenied) {
          // On Android 13+, use READ_MEDIA_* permissions
          final images = await Permission.photos.request();
          final videos = await Permission.videos.request();
          final storage = await Permission.storage.request();

          if (images.isDenied && videos.isDenied && storage.isDenied) {
            throw Exception('Gallery access permission denied');
          }
        }
      } else {
        // iOS
        final photos = await Permission.photos.request();
        if (photos.isDenied)
          throw Exception('Gallery access permission denied');
      }

      // ✅ Step 2: Open picker
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 10,
          requestType: RequestType.common,
          themeColor: Colors.blue,
        ),
      );

      if (assets == null || assets.isEmpty) return;

      for (final asset in assets) {
        final file = await asset.file;
        if (file == null) continue;

        final type = (asset.type == AssetType.video) ? 'video' : 'image';
        await _sendGroupMedia(file, type);
      }
    } catch (e) {
      _handleError('accessing gallery', e);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image == null) return; // user canceled
      await _sendGroupMedia(File(image.path), 'image');
    } catch (e) {
      _handleError('accessing camera', e);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return; // user canceled

      for (final picked in result.files) {
        if (picked.path == null) continue;

        final file = File(picked.path!);
        if (!file.existsSync()) continue;

        // ✅ All picked from FilePicker behave as documents
        await _sendGroupMedia(file, 'document');
      }
    } catch (e) {
      _handleError('picking document', e);
    }
  }

  Future<void> _pickContact() async {
    try {
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        SnackbarMessage.failedsnack('Contacts permission denied', context);
        return;
      }

      final Contact? contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final contactInfo = {
          'name': contact.displayName,
          'phones': contact.phones.map((p) => p.number).toList(),
          'emails': contact.emails.map((e) => e.address).toList(),
        };

        final groupProvider = Provider.of<GroupProvider>(
          context,
          listen: false,
        );
        await groupProvider.sendGroupMessage(
          groupId: widget.groupId,
          text: '📞 Contact: ${contact.displayName}',
          messageType: 'contact',
          contactInfo: contactInfo,
        );
      }
    } catch (e) {
      _handleError('picking contact', e);
    }
  }

  // In your GroupChatScreen class, add these methods:

  List<Map<String, dynamic>> _getMediaMessages(
    List<GroupMessageModel> messages,
  ) {
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
            'text': message.text ?? '',
            'timestamp': message.timestamp,
            'messageType': message.messageType,
            'senderId': message.senderId,
            'senderName': message.senderName,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _getLinkMessages(
    List<GroupMessageModel> messages,
  ) {
    final urlRegex = RegExp(
      r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );

    return messages
        .where(
          (message) => message.text != null && urlRegex.hasMatch(message.text!),
        )
        .map(
          (message) => {
            'text': message.text!,
            'timestamp': message.timestamp,
            'senderId': message.senderId,
            'senderName': message.senderName,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _getDocumentMessages(
    List<GroupMessageModel> messages,
  ) {
    return messages
        .where((message) => message.messageType == 'document')
        .map(
          (message) => {
            'text': message.text ?? 'Document',
            'mediaUrl': message.mediaUrl,
            'timestamp': message.timestamp,
            'senderId': message.senderId,
            'senderName': message.senderName,
          },
        )
        .toList();
  }

  Future<void> _sendGroupMedia(File file, String type) async {
    if (!await _validateFile(file, type)) return;

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uploadedUrl = await _uploadToCloudinary(file);
      Navigator.pop(context);

      if (uploadedUrl == null) return; // skip null upload

      String text;
      switch (type) {
        case 'image':
          text = '📷 Image';
          break;
        case 'video':
          text = '🎥 Video';
          break;
        case 'document':
        default:
          text = '📄 Document';
          break;
      }

      await groupProvider.sendGroupMessage(
        groupId: widget.groupId,
        text: text,
        mediaUrl: uploadedUrl,
        messageType: type,
      );

      if (_isNearBottom) _scrollToBottom();
    } catch (e) {
      Navigator.pop(context);
      _handleError('sending media', e);
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.sendGroupMessage(
      groupId: widget.groupId,
      text: text,
      messageType: 'text',
    );

    _msgController.clear();
    if (_isNearBottom) {
      Future.delayed(Duration(milliseconds: 200), _scrollToBottom);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // ✅ Changed from maxScrollExtent to 0
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  // Add these methods to _GroupChatScreenState

  void _toggleMessageSelection(String messageId) {
    if (messageId.isEmpty) return; // Safety check

    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
      } else {
        _selectedMessages.add(messageId);
      }

      // Update selection mode
      _isSelecting = _selectedMessages.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessages.clear();
      _isSelecting = false;
    });
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessages.isEmpty) return;

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    try {
      // Check if current user is admin
      final isAdmin = await groupProvider.isCurrentUserAdmin(widget.groupId);

      bool? deleteForEveryone;

      if (isAdmin) {
        // Show dialog for admin to choose delete option
        deleteForEveryone = await showDialog<bool>(
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
                        () => Navigator.pop(context, false), // Delete for me
                    child: const Text(
                      "Delete for me",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () =>
                            Navigator.pop(context, true), // Delete for everyone
                    child: const Text(
                      "Delete for everyone",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        );

        // If user presses back (null), do nothing
        if (deleteForEveryone == null) {
          return;
        }
      } else {
        // Regular users can only delete for themselves
        deleteForEveryone = false;
      }

      await groupProvider.deleteMultipleGroupMessages(
        groupId: widget.groupId,
        messageIds: _selectedMessages.toList(),
        deleteForEveryone: deleteForEveryone,
      );

      _clearSelection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${_selectedMessages.length} message(s)'),
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

  Future<void> _toggleAudioPlayback(String url) async {
    try {
      if (_currentPlayingUrl == url && _isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        if (_isPlaying) await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _currentPlayingUrl = url;
          _isPlaying = true;
          _audioPosition = Duration.zero;
        });
        Future.delayed(const Duration(milliseconds: 100), () async {
          final d = await _audioPlayer.getDuration();
          if (mounted && d != null) setState(() => _audioDuration = d);
        });
      }
    } catch (e) {
      _handleError('audio playback', e);
    }
  }

  // Add these URL detection methods
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

      // Check if URL can be launched
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
        print('❌ Cannot launch URL');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open: ${url.host}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
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

  Widget _buildGroupTextMessage(GroupMessageModel message, bool isMe) {
    final time = formatTime(message.timestamp);
    final text = message.text ?? '';

    // FIXED: Use enhanced user name fetching
    final String senderName;
    if (isMe) {
      senderName = 'You';
    } else {
      // Check if user exists in contacts first
      senderName = _getUserName(message.senderId!, message.senderName);
    }

    // Check if message contains URL
    final containsUrl = _containsUrl(text);
    final url = containsUrl ? _extractFirstUrl(text) : null;
    final isValidUrl = url != null ? _isValidUrl(url) : false;
    final displayUrl = url != null ? _extractDisplayUrl(url) : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xff1565C0) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            if (!isMe) const SizedBox(height: 6),

            // URL Preview Section
            if (containsUrl && isValidUrl)
              GestureDetector(
                onTap: () => _launchUrl(url),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // URL preview
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: isMe ? Colors.white : Colors.blue,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              displayUrl,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Click hint
                      Text(
                        'Tap to open link',
                        style: TextStyle(
                          color:
                              isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (containsUrl && isValidUrl) const SizedBox(height: 8),

            // Message Text
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),

            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (isMe) const SizedBox(width: 6),
                if (isMe) _buildMessageStatus(message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatus(GroupMessageModel message) {
    if (message.isRead == true) {
      return Icon(Icons.done_all, size: 14, color: Colors.blue);
    } else if (message.isDelivered == true) {
      return Icon(Icons.done_all, size: 14, color: Colors.white70);
    } else {
      return Icon(Icons.done, size: 14, color: Colors.white70);
    }
  }

  Widget _buildGroupImageMessage(GroupMessageModel message, bool isMe) {
    final url = message.mediaUrl;
    final time = formatTime(message.timestamp);

    // FIXED: Use enhanced user name fetching
    final String senderName =
        isMe ? 'You' : _getUserName(message.senderId!, message.senderName);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isMe ? Color(0xff1565C0) : Colors.grey.shade400,
            width: 5, // your desired border width
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            color: isMe ? const Color(0xff1565C0) : Colors.grey.shade200,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.55,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (url != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullScreenMediaViewer(
                                mediaUrl: message.mediaUrl!,
                                heroTag: message.mediaUrl!,
                              ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: url,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[300],
                              ),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: Icon(Icons.broken_image),
                            ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) const SizedBox(width: 6),
                      if (isMe) _buildMessageStatus(message),
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

  Widget _buildGroupAudioMessage(GroupMessageModel message, bool isMe) {
    final url = message.mediaUrl ?? '';
    final isCurrentlyPlaying = _currentPlayingUrl == url && _isPlaying;
    final time = formatTime(message.timestamp);

    // FIXED: Use enhanced user name fetching
    final String senderName =
        isMe ? 'You' : _getUserName(message.senderId!, message.senderName);

    final progress =
        _audioDuration.inMilliseconds > 0 && isCurrentlyPlaying
            ? (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds)
            : 0.0;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xff1565C0) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            if (!isMe) const SizedBox(height: 6),
            Row(
              children: [
                InkWell(
                  onTap: () => _toggleAudioPlayback(url),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        isMe ? Colors.white.withOpacity(0.2) : Colors.white,
                    child: Icon(
                      isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                      color: isMe ? Colors.white : const Color(0xff1565C0),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(25, (index) {
                        final heights = [
                          8.0,
                          12.0,
                          16.0,
                          10.0,
                          14.0,
                          18.0,
                          8.0,
                          20.0,
                          12.0,
                          16.0,
                          14.0,
                          10.0,
                          18.0,
                          8.0,
                          16.0,
                          12.0,
                          20.0,
                          14.0,
                          10.0,
                          16.0,
                          8.0,
                          18.0,
                          12.0,
                          14.0,
                          10.0,
                        ];
                        final isPlayed =
                            isCurrentlyPlaying && (index / 25) <= progress;

                        return Container(
                          width: 2.5,
                          height: heights[index],
                          decoration: BoxDecoration(
                            color:
                                isPlayed
                                    ? (isMe
                                        ? Colors.white
                                        : const Color(0xff1565C0))
                                    : (isMe
                                        ? Colors.white.withOpacity(0.4)
                                        : Colors.grey.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isCurrentlyPlaying
                      ? formatDuration(_audioPosition)
                      : formatDuration(_audioDuration),
                  style: TextStyle(
                    color:
                        isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                if (isMe) const SizedBox(width: 6),
                if (isMe) _buildMessageStatus(message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDocumentMessage(GroupMessageModel message, bool isMe) {
    final time = formatTime(message.timestamp);
    final url = message.mediaUrl ?? '';

    final String senderName =
        isMe ? 'You' : _getUserName(message.senderId!, message.senderName);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xff1565C0) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show sender name for received messages
            if (!isMe) ...[
              Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Document preview
            GestureDetector(
              onTap: () => _openDocument(message.mediaUrl!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Document icon container
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
                      _getDocumentIcon(url),
                      size: 28,
                      color: isMe ? Colors.white : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Document info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFileNameFromUrl(url),
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

                  // Open icon
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ],
              ),
            ),

            // Time and status
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                if (isMe) const SizedBox(width: 6),
                if (isMe) _buildMessageStatus(message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add this helper method to get appropriate icon based on file type
  IconData _getDocumentIcon(String? url) {
    if (url == null) return Icons.insert_drive_file;

    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx')) {
      return Icons.description;
    } else if (lowerUrl.contains('.xls') || lowerUrl.contains('.xlsx')) {
      return Icons.table_chart;
    } else if (lowerUrl.contains('.ppt') || lowerUrl.contains('.pptx')) {
      return Icons.slideshow;
    } else if (lowerUrl.contains('.txt')) {
      return Icons.text_snippet;
    } else if (lowerUrl.contains('.zip') || lowerUrl.contains('.rar')) {
      return Icons.folder_zip;
    } else {
      return Icons.insert_drive_file;
    }
  }

  // FIXED: Enhanced file name extraction from URL
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isNotEmpty) {
        String fileName = pathSegments.last;

        // Remove Cloudinary transformation parameters from filename
        if (url.contains('cloudinary.com')) {
          // Cloudinary URLs often have transformations in the path
          // Look for the actual filename after transformations
          final parts = fileName.split('/');
          if (parts.length > 1) {
            fileName = parts.last;
          }

          // Remove version numbers and other parameters
          fileName = fileName.replaceAll(RegExp(r'v\d+/'), '');
        }

        // Decode URL-encoded characters
        fileName = Uri.decodeComponent(fileName);

        // If no proper extension, try to determine from content type or URL
        if (!fileName.contains('.')) {
          if (url.toLowerCase().contains('.pdf')) return '$fileName.pdf';
          if (url.toLowerCase().contains('.doc')) return '$fileName.docx';
          if (url.toLowerCase().contains('.xls')) return '$fileName.xlsx';
          if (url.toLowerCase().contains('.ppt')) return '$fileName.pptx';
          if (url.toLowerCase().contains('.txt')) return '$fileName.txt';
          return '$fileName.file';
        }

        return fileName;
      }
      return 'document.pdf';
    } catch (e) {
      print('Error parsing filename from URL: $e');
      return 'document.pdf';
    }
  }

  Future<void> _openDocument(String url) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  // SizedBox(height: 16),
                  // Text(
                  //   'Opening document...',
                  //   style: TextStyle(color: Colors.white),
                  // ),
                ],
              ),
            ),
      );

      // Download file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw 'Failed to download document. Status: ${response.statusCode}';
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Extract proper filename from URL
      final fileName = _getFileNameFromUrl(url);

      // Save file locally with proper name
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      Navigator.pop(context);

      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        SnackbarMessage.failedsnack(
          'Could not open the document: ${result.message}',
          context,
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      SnackbarMessage.failedsnack('Error opening document: $e', context);
    }
  }

  Widget _buildGroupContactMessage(GroupMessageModel message, bool isMe) {
    final contact = message.contactInfo ?? {};
    final name = contact['name'] ?? 'Unknown';
    final phones = (contact['phones'] ?? []);
    final time = formatTime(message.timestamp);

    // FIXED: Use enhanced user name fetching
    final String senderName =
        isMe ? 'You' : _getUserName(message.senderId!, message.senderName);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xff1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            if (!isMe) const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Contact: $name',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (phones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Phone: ${phones.first}',
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (isMe) const SizedBox(width: 6),
                if (isMe) _buildMessageStatus(message),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Enhanced _buildMessagesList method
  Widget _buildMessagesList() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    return StreamBuilder<List<GroupMessageModel>>(
      stream: _getMessageStream(groupProvider),
      builder: (context, snapshot) {
        // ✅ Load initial cached messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_hasCachedMessages) {
            _loadInitialMessages();
          }
        });

        // ✅ OPTIMIZED: Show cached data immediately
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_hasCachedMessages && _cachedMessages!.isNotEmpty) {
            return _buildMessagesListFromCache();
          }
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          if (_hasCachedMessages && _cachedMessages!.isNotEmpty) {
            return _buildMessagesListFromCache();
          }
          return _buildLoadingState();
        }

        final messages = snapshot.data ?? [];

        // ✅ UPDATE CACHE and loading state
        if (messages.isNotEmpty) {
          _cachedMessages = messages;
          _hasCachedMessages = true;

          // Cache messages in provider for future use
          groupProvider.cacheGroupMessages(widget.groupId, messages);
        }

        if (messages.isEmpty && !_hasCachedMessages) {
          return Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        if (snapshot.hasData && mounted && !_messagesMarkedAsRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markMessagesAsRead();
          });
        }

        // ✅ Use cached messages if no new messages
        final messagesToDisplay =
            messages.isNotEmpty ? messages : _cachedMessages;

        return _buildMessagesListView(messagesToDisplay!);
      },
    );
  }

  // ✅ NEW: Build messages list from cache (instant loading)
  Widget _buildMessagesListFromCache() {
    if (_cachedMessages!.isEmpty) {
      return Center(
        child: Text('No messages yet', style: TextStyle(color: Colors.white54)),
      );
    }

    return _buildMessagesListView(_cachedMessages!);
  }

  // ✅ NEW: Common method to build list view from messages
  Widget _buildMessagesListView(List<GroupMessageModel> messages) {
    // ✅ Don't sort - keep Firebase's descending order for reverse list
    final sortedMessages = messages;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(10),
      itemCount: sortedMessages.length,
      addAutomaticKeepAlives: true,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final msg = sortedMessages[index];
        final messageId = msg.messageId ?? index.toString();

        final deletedFor = msg.deletedFor ?? [];
        if (deletedFor.contains(currentUserId)) {
          return const SizedBox.shrink();
        }

        if (msg.messageType == 'system' || msg.senderId == 'system') {
          return _buildSystemMessage(msg);
        }

        final isMe = msg.senderId == currentUserId;
        final isSelected = _selectedMessages.contains(messageId);

        Widget messageWidget;
        switch (msg.messageType) {
          case 'image':
            messageWidget = _buildGroupImageMessage(msg, isMe);
            break;
          case 'video':
            messageWidget = _buildGroupVideoMessage(msg, isMe);
            break;
          case 'audio':
            messageWidget = _buildGroupAudioMessage(msg, isMe);
            break;
          case 'document':
            messageWidget = _buildGroupDocumentMessage(msg, isMe);
            break;
          case 'contact':
            messageWidget = _buildGroupContactMessage(msg, isMe);
            break;
          default:
            messageWidget = _buildGroupTextMessage(msg, isMe);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => _toggleMessageSelection(messageId),
          onTap: _isSelecting ? () => _toggleMessageSelection(messageId) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleMessageSelection(messageId),
                      activeColor: Colors.blue,
                      checkColor: Colors.white,
                    ),
                  ),
                Expanded(child: messageWidget),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Enhanced method to get user name with multiple fallbacks (same as chat screen)
  String _getUserName(String userId, String? messageSenderName) {
    // 1. Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    // 2. Use message sender name if available and valid
    if (messageSenderName != null &&
        messageSenderName.isNotEmpty &&
        messageSenderName != 'Unknown User' &&
        messageSenderName != 'User') {
      _userNameCache[userId] = messageSenderName;
      return messageSenderName;
    }

    // 3. Fetch from Firestore asynchronously
    _fetchUserDataAsync(userId);

    // 4. Return temporary name while fetching
    return 'Loading...';
  }

  // ✅ Fetch user data asynchronously and update UI (same as chat screen)
  Future<void> _fetchUserDataAsync(String userId) async {
    if (_userNameCache.containsKey(userId)) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        final userName =
            userData?['name'] ??
            userData?['phone'] ??
            'User ${userId.substring(0, 4)}';
        final userPhoto = userData?['photoUrl'];

        setState(() {
          _userNameCache[userId] = userName;
          if (userPhoto != null) {
            _userPhotoCache[userId] = userPhoto;
          }
        });

        print('✅ Fetched user data for $userId: $userName');
      }
    } catch (e) {
      print('❌ Error fetching user data for $userId: $e');
      if (mounted) {
        setState(() {
          _userNameCache[userId] = 'User ${userId.substring(0, 4)}';
        });
      }
    }
  }

  Widget _buildSystemMessage(GroupMessageModel message) {
    // Determine icon based on message content
    IconData? icon;
    Color? bubbleColor;

    if (message.text?.contains('left') ?? false) {
      icon = Icons.exit_to_app;
      bubbleColor = Colors.red.withOpacity(0.1);
    } else if (message.text?.contains('added') ?? false) {
      icon = Icons.person_add;
      bubbleColor = Colors.green.withOpacity(0.1);
    } else if (message.text?.contains('admin') ?? false) {
      icon = Icons.star;
      bubbleColor = Colors.blue.withOpacity(0.1);
    } else if (message.text?.contains('removed') ?? false) {
      icon = Icons.person_remove;
      bubbleColor = Colors.orange.withOpacity(0.1);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: bubbleColor ?? Colors.grey[800]!.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey[600]!.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
              ],
              Text(
                message.text ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupVideoMessage(GroupMessageModel message, bool isMe) {
    final url = message.mediaUrl;
    final time = formatTime(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 210),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isMe ? Color(0xff1565C0) : Colors.grey.shade400,
            width: 5, // your desired border width
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            color: isMe ? const Color(0xff1565C0) : Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (url != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FullScreenMediaViewer(
                                mediaUrl: message.mediaUrl!,
                                heroTag: url,
                              ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: _getVideoThumbnailUrl(url),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[300],
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: Icon(Icons.videocam_off),
                              ),
                        ),
                        Positioned.fill(
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
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6, top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) const SizedBox(width: 6),
                      if (isMe) _buildMessageStatus(message),
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

  Widget _buildLoadingState() {
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
              Container(
                width: 200,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      isMe
                          ? const Color(0xff1565C0).withOpacity(0.3)
                          : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 15,
            children: [
              _buildAttachmentOption(Icons.camera_alt, "Camera", () {
                Navigator.pop(context);
                _pickImageFromCamera();
              }),
              _buildAttachmentOption(Icons.contacts, "Contact", () {
                Navigator.pop(context);
                _pickContact();
              }),
              _buildAttachmentOption(Icons.image, "Gallery", () {
                Navigator.pop(context);
                _pickImageFromGallery();
              }),
              // _buildAttachmentOption(Icons.location_on, "Location", () {
              //   Navigator.pop(context);
              //   SnackbarMessage.failedsnack(
              //     'Location not implemented',
              //     context,
              //   );
              // }),
              _buildAttachmentOption(Icons.insert_drive_file, "Document", () {
                Navigator.pop(context);
                _pickDocument();
              }),
            ],
          ),
          const SizedBox(height: 12),
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
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xff40C4FF),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: const Color(0xff292929),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 24),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _recordingAnimation!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _recordingAnimation!.value,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(width: 12),
                Text(
                  'Recording...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Text(
                  formatDuration(_recordingDuration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xff40C4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final size = MediaQuery.of(context).size;

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
                builder: (_) => _buildAttachmentBottomSheet(),
              );
            },
            child: Container(
              height: size.height * .05,
              width: size.width * .1,
              decoration: const BoxDecoration(
                color: Color(0xff3e3e3e),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xff40C4FF), size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _msgController,
              cursorColor: const Color(0xff40C4FF),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message to group...",
                hintStyle: const TextStyle(color: Colors.white54),
                fillColor: const Color(0xff3e3e3e),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onLongPress:
                _msgController.text.trim().isEmpty ? _startRecording : null,
            onTap: () {
              if (_msgController.text.trim().isNotEmpty) {
                _sendTextMessage();
              }
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Color(0xff40C4FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _msgController.text.trim().isNotEmpty ? Icons.send : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    final size = MediaQuery.of(context).size;
    final memberCountText =
        widget.memberCount != null
            ? '${widget.memberCount} members'
            : 'Group Chat';

    return Container(
      height: size.height * .1,
      width: double.infinity,
      decoration: BoxDecoration(color: Color(0xff292929)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            InkWell(
              onTap:
                  _isSelecting ? _clearSelection : () => Navigator.pop(context),
              child: Container(
                height: size.height * .05,
                width: size.width * .1,
                decoration: BoxDecoration(
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
              CircleAvatar(
                radius: 23,
                backgroundImage:
                    widget.groupImage != null &&
                            widget.groupImage!.startsWith('http')
                        ? NetworkImage(widget.groupImage!)
                        : null,
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
                        : widget.groupName,
                    softWrap: true,
                    style: Apptexts.titlestyle.copyWith(
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isSelecting)
                    Text(
                      memberCountText,
                      style: Apptexts.bodystyle.copyWith(color: Colors.white70),
                    ),
                ],
              ),
            ),
            if (_isSelecting) ...[
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelectedMessages,
              ),
            ] else ...[
              SizedBox(width: size.width * .02),
              Image.asset(
                "assets/images/video.png",
                height: size.height * .06,
                width: size.width * .12,
              ),
              SizedBox(width: size.width * .02),
              GestureDetector(
                onTap: () {},
                child: Icon(Icons.call, color: Colors.white, size: 25),
              ),
              SizedBox(width: size.width * .02),
              GestureDetector(
                onTap: () {
                  final groupProvider = Provider.of<GroupProvider>(
                    context,
                    listen: false,
                  );

                  // Get messages from cache without loading
                  final cachedMessages = groupProvider.getCachedGroupMessages(
                    widget.groupId,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => GroupInfoScreen(
                            groupId: widget.groupId,
                            mediaMessages: _getMediaMessages(cachedMessages!),
                            linkMessages: _getLinkMessages(cachedMessages),
                            documentMessages: _getDocumentMessages(
                              cachedMessages,
                            ),
                          ),
                    ),
                  );
                },
                child: Icon(Icons.more_vert, color: Colors.white, size: 25),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff2c2d3a),
        body: Column(
          children: [
            _buildCustomHeader(),
            Expanded(child: _buildMessagesList()),
            const Divider(color: Color(0xff595a6d), height: 1),
            _isRecording ? _buildRecordingUI() : _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}
