import 'package:chat_app/view/constants/text.dart';
import 'package:chat_app/view/screens/homepage.dart/addtogroupscreen.dart';
import 'package:chat_app/view/screens/homepage.dart/showchatmedia.dart';
import 'package:chat_app/view_model/chatstate.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ContactInfoScreen extends StatefulWidget {
  final String contactName;
  final String contactPhone;
  final String contactImageUrl;
  final String chatId;
  final String currentUserId;
  final List<Map<String, dynamic>> mediaMessages;
  final List<Map<String, dynamic>> linkMessages;
  final List<Map<String, dynamic>> documentMessages;
  final String receiverId;

  const ContactInfoScreen({
    super.key,
    required this.contactName,
    required this.contactPhone,
    required this.contactImageUrl,
    required this.chatId,
    required this.currentUserId,
    required this.mediaMessages,
    required this.linkMessages,
    required this.documentMessages,
    required this.receiverId,
  });

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  bool muteNotification = false;
  bool protectedChat = false;
  bool hideChat = false;
  bool hideChatHistory = false;
  bool _isBlocked = false;
  bool _isLoadingBlockStatus = true;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  // Check if user is blocked
  Future<void> _checkBlockStatus() async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final isBlocked = await chatProvider.isUserBlocked(widget.receiverId);
      
      if (mounted) {
        setState(() {
          _isBlocked = isBlocked;
          _isLoadingBlockStatus = false;
        });
      }
    } catch (e) {
      print('❌ Error checking block status: $e');
      if (mounted) {
        setState(() {
          _isLoadingBlockStatus = false;
        });
      }
    }
  }

  // Block/Unblock using receiverId
  Future<void> _toggleBlockUser() async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (_isBlocked) {
        await chatProvider.unblockUser(widget.receiverId);
        setState(() {
          _isBlocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unblocked ${widget.contactName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await chatProvider.blockUser(widget.receiverId);
        setState(() {
          _isBlocked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blocked ${widget.contactName}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Notify chat screen to refresh
      _notifyChatScreen();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }
    void _notifyChatScreen() {
    print('🔄 Block status changed - chat screen should refresh');
  }

  // Show block confirmation dialog
  void _showBlockDialog() {
    showDialog(
      context: context,
      builder:
          (context) => BlockUserDialog(
            userName: widget.contactName,
            isCurrentlyBlocked: _isBlocked,
            onBlock: _toggleBlockUser,
            onUnblock: _toggleBlockUser,
          ),
    );
  }

  // Navigate to group selection
  void _navigateToGroupSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GroupSelectionScreen(
              contactId:
                  widget.contactPhone, // Using phone as ID, adjust as needed
              contactName: widget.contactName,
              contactImageUrl: widget.contactImageUrl,
            ),
      ),
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            // Profile Image
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  widget.contactImageUrl.startsWith("http")
                      ? NetworkImage(widget.contactImageUrl)
                      : AssetImage(widget.contactImageUrl) as ImageProvider,
            ),
            SizedBox(height: size.height * .03),

            // Name
            Text(
              widget.contactName,
              style: Apptexts.titlestyle.copyWith(color: Colors.white),
            ),

            SizedBox(height: size.height * .01),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.contactPhone,
                  style: TextStyle(color: Color(0xffF0F0F3), fontSize: 14),
                ),
                SizedBox(width: size.width * .02),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.contactPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied to clipboard'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Icon(Icons.copy, size: 16, color: Color(0xffF0F0F3)),
                ),
              ],
            ),

            SizedBox(height: size.height * .03),
            Divider(color: Colors.white24),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatDetailsPage(
                          chatId: widget.chatId,
                          currentUserId: widget.currentUserId,
                          contactName: widget.contactName,
                          mediaMessages: widget.mediaMessages,
                          linkMessages: widget.linkMessages,
                          documentMessages: widget.documentMessages,
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
              title: "Add To Group",
              showArrow: true,
              onTap: _navigateToGroupSelection, // Add this parameter
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
            _buildOption(
              image: "assets/images/block.png",
              title: _isBlocked ? "Unblock" : "Block",
              showArrow: false,
              onTap: _showBlockDialog, // Add this parameter
              trailing:
                  _isLoadingBlockStatus
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : null,
            ),
            SizedBox(height: size.height * .03),
          ],
        ),
      ),
    );
  }

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
      onTap: onTap, // Use the onTap parameter
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

class BlockUserDialog extends StatelessWidget {
  final String userName;
  final bool isCurrentlyBlocked;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;

  const BlockUserDialog({
    super.key,
    required this.userName,
    required this.isCurrentlyBlocked,
    required this.onBlock,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xff3e3e3e),
      title: Text(
        isCurrentlyBlocked ? 'Unblock $userName?' : 'Block $userName?',
        style: const TextStyle(color: Colors.white),
      ),
      content: Text(
        isCurrentlyBlocked
            ? 'They will be able to send you messages and call you again.'
            : 'They will no longer be able to send you messages or call you.',
        style: TextStyle(color: Colors.grey.shade300),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (isCurrentlyBlocked) {
              onUnblock();
            } else {
              onBlock();
            }
          },
          child: Text(
            isCurrentlyBlocked ? 'UNBLOCK' : 'BLOCK',
            style: TextStyle(
              color: isCurrentlyBlocked ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}
