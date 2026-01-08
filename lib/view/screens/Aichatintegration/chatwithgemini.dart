
import 'package:chat_app/view/constants/jumpingloadingindictor.dart';
import 'package:chat_app/model/aimessagemodel.dart';
import 'package:chat_app/view_model/aichatstate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  late AiChatProvider _aiChatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aiChatProvider.cleanupOldMessages();
    });
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });
    _msgController.clear();

    try {
      await _aiChatProvider.sendMessage(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  // Build received message (AI message)
  Widget _buildReceivedMessage(String text, String time) {
    Size size = MediaQuery.of(context).size;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        constraints: BoxConstraints(maxWidth: size.width * 0.75),
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
              style: TextStyle(
                fontSize: 16,
                color: Color(0xff2C2D3A),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Build sent message (User message)
  Widget _buildSentMessage(String text, String time) {
    Size size = MediaQuery.of(context).size;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: size.width * 0.75),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Color(0xffE9EAEB)),
                ),
                const SizedBox(width: 5),
                Icon(Icons.done_all, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build typing indicator with jumping dots
  Widget _buildTypingIndicator() {
    Size size = MediaQuery.of(context).size;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        constraints: BoxConstraints(maxWidth: size.width * 0.75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size.width * 0.05),
            topRight: Radius.circular(size.width * 0.05),
            bottomRight: Radius.circular(size.width * 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            JumpingDotsLoader(color: Colors.grey[600]!, size: 8, numDots: 3),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final userId = 'current_user_id'; // Replace with actual user ID from auth

    return ChangeNotifierProvider(
      create: (context) => AiChatProvider(userId),
      child: Consumer<AiChatProvider>(
        builder: (context, aiChatProvider, child) {
          _aiChatProvider = aiChatProvider;

          return SafeArea(
            child: Scaffold(
              backgroundColor: const Color(0xff2c2d3a),
              body: Column(
                children: [
                  // 🔵 Custom E-Chat Header
                  Container(
                    width: double.infinity,
                    height: size.height * .1,
                    decoration: BoxDecoration(
                      color: const Color(0xff292929),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(size.width * 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: size.height * .05,
                              width: size.width * .1,
                              decoration: const BoxDecoration(
                                color: Color(0xff3e3e3e),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: size.width * 0.05),
                          Text(
                            "Let's Talk with Gemini",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () {
                              _showClearChatDialog(aiChatProvider);
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            tooltip: 'Clear chat',
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<List<AiMessage>>(
                      stream: aiChatProvider.getMessages(),
                      builder: (context, snapshot) {
                        final cachedMessages =
                            aiChatProvider.getCachedMessages();
                        final hasCachedData = aiChatProvider.hasCachedData;

                        List<AiMessage> messagesToShow = [];

                        if (hasCachedData) {
                          messagesToShow = cachedMessages;
                        }

                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          messagesToShow = snapshot.data!;
                        }

                        if (messagesToShow.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Start a conversation with AI',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(10),
                          itemCount:
                              messagesToShow.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isSending && index == 0) {
                              return _buildTypingIndicator();
                            }

                            final messageIndex = _isSending ? index - 1 : index;
                            final msg = messagesToShow[messageIndex];
                            final time = _formatTime(msg.timestamp);

                            if (msg.isUser) {
                              return _buildSentMessage(msg.text, time);
                            } else {
                              return _buildReceivedMessage(msg.text, time);
                            }
                          },
                        );
                      },
                    ),
                  ),

                  // 📝 Message Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(color: Color(0xff292929)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xff40C4FF),
                            decoration: InputDecoration(
                              hintText: "Ask something...",
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xff3e3e3e),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: CircleAvatar(
                            radius: 27,
                            backgroundColor:
                                _isSending
                                    ? Colors.grey
                                    : const Color(0xff40C4FF),
                            child:
                                _isSending
                                    ? JumpingDotsLoader(
                                      color: Colors.white,
                                      size: 6,
                                      numDots: 3,
                                    )
                                    : Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showClearChatDialog(AiChatProvider aiChatProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear Chat History'),
            content: Text(
              'Are you sure you want to clear all chat history? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await aiChatProvider.clearChatHistory();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chat history cleared')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to clear chat history')),
                    );
                  }
                },
                child: Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
