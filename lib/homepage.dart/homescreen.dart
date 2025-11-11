import 'package:chat_app/constants/text.dart';
import 'package:chat_app/homepage.dart/addgroup.dart';
import 'package:chat_app/homepage.dart/showfriendlist.dart';
import 'package:chat_app/homepage.dart/chatscreen.dart';
import 'package:chat_app/state/chatstate.dart';
import 'package:chat_app/state/unread_count_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  bool isclicked = false;
  bool isSearching = false;
  final GlobalKey _iconKey = GlobalKey();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Map<String, String>> _userCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xff292929),
      body: Column(
        children: [
          // Header Section
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
              child:
                  isSearching
                      ? Padding(
                        padding: const EdgeInsets.only(left: 20, right: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                cursorColor: Color(0xff135CAF),
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintStyle: TextStyle(
                                    color: Color(0xff9A9BB1),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: Apptexts.bodystyle.copyWith(
                                  color: Colors.black,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  isSearching = false;
                                  searchQuery = "";
                                  _searchController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      )
                      : Row(
                        children: [
                          Image.asset(
                            'assets/images/Logo.png',
                            width: size.width * .25,
                          ),
                          Text(
                            "E-Chat",
                            style: Apptexts.titlestyle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              setState(() {
                                isSearching = true;
                              });
                            },
                          ),
                          IconButton(
                            key: _iconKey,
                            icon:
                                isclicked
                                    ? Icon(
                                      Icons.cancel,
                                      color: Colors.white,
                                      size: 32,
                                    )
                                    : Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            onPressed: () async {
                              if (!isclicked) {
                                setState(() => isclicked = true);
                                await _showAddMenu(context);
                                setState(() => isclicked = false);
                              } else {
                                setState(() => isclicked = false);
                              }
                            },
                          ),
                        ],
                      ),
            ),
          ),
          SizedBox(height: size.height * .02),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: currentUserId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: _buildChatSkeleton(size));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading chats",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No chats yet",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Start a conversation with your friends!",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data!.docs;

                // Filter individual chats
                final individualChats =
                    chats.where((chat) {
                      final data = chat.data() as Map<String, dynamic>;
                      final participants = List<String>.from(
                        data['participants'] ?? [],
                      );
                      return data['isGroup'] != true &&
                          participants.length == 2 &&
                          participants.contains(currentUserId);
                    }).toList();

                // Sort by last message time
                individualChats.sort((a, b) {
                  final aTime = a['lastMessageTime']?.toDate() ?? DateTime(0);
                  final bTime = b['lastMessageTime']?.toDate() ?? DateTime(0);
                  return bTime.compareTo(aTime);
                });

                // Filter by search query
                List<QueryDocumentSnapshot> filteredChats = individualChats;
                if (searchQuery.isNotEmpty) {
                  filteredChats =
                      individualChats.where((chat) {
                        final data = chat.data() as Map<String, dynamic>;
                        final otherParticipantId = _getOtherParticipantId(
                          data,
                          currentUserId,
                        );
                        return otherParticipantId.isNotEmpty &&
                            otherParticipantId.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            );
                      }).toList();
                }
                if (filteredChats.isEmpty && searchQuery.isNotEmpty) {
                  return Center(
                    child: Text(
                      "No chats found for '$searchQuery'",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No individual chats yet",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Start a conversation with your friends!",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filteredChats.length,
                  itemBuilder: (BuildContext context, int index) {
                    final chat = filteredChats[index];
                    final data = chat.data() as Map<String, dynamic>;
                    return _buildIndividualChatListItem(chat, data, size);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // In your Homescreen widget, update the individual chat list item
  Widget _buildIndividualChatListItem(
    QueryDocumentSnapshot chat,
    Map<String, dynamic> data,
    Size size,
  ) {
    final chatId = chat.id;
    final lastMessage = data['lastMessage'] ?? 'Start a conversation';
    final lastMessageTime =
        data['lastMessageTime'] != null
            ? _formatTime(data['lastMessageTime'].toDate())
            : '';

    final otherParticipantId = _getOtherParticipantId(data, currentUserId);

    return FutureBuilder<Map<String, String>>(
      future: _getUserInfo(otherParticipantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChatSkeleton(size);
        }

        final userInfo =
            snapshot.data ??
            {
              'name': 'Unknown',
              'image': 'assets/images/profile.png',
              'phone': '',
            };

        // Use StreamBuilder for real-time unread count
        return StreamBuilder<int>(
          stream: Provider.of<UnreadCountProvider>(
            context,
            listen: false,
          ).getChatUnreadCount(chatId),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;
            final hasUnreadMessages = unreadCount > 0;

            return InkWell(
              // ✅ Changed from GestureDetector
              onTap: () async {
                // ✅ Mark messages as read
                final chatProvider = ChatProvider();
                await chatProvider.markMessagesAsRead(chatId, currentUserId);

                // ✅ Navigate to chat screen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Chatscreen(
                          name: userInfo['name'].toString(),
                          image: userInfo['image'].toString(),
                          receiverId: otherParticipantId,
                          phone: userInfo['phone'].toString(),
                          senderId: currentUserId,
                        ),
                  ),
                );

                // ✅ Refresh after returning
                if (mounted) {
                  setState(() {});
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              userInfo['image']!.startsWith('http')
                                  ? NetworkImage(userInfo['image']!)
                                  : AssetImage(userInfo['image']!)
                                      as ImageProvider,
                        ),
                        if (hasUnreadMessages)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xff40C4FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xff292929),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userInfo['name']!,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  hasUnreadMessages
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage,
                            style: TextStyle(
                              color:
                                  hasUnreadMessages
                                      ? Colors.white
                                      : const Color(0xff9A9BB1),
                              fontWeight:
                                  hasUnreadMessages
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          lastMessageTime,
                          style: const TextStyle(
                            color: Color(0xff9A9BB1),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (hasUnreadMessages)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(minWidth: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xff40C4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getOtherParticipantId(
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final participants = List<String>.from(data['participants'] ?? []);
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  Future<Map<String, String>> _getUserInfo(String userId) async {
    // Return from cache if available
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      Map<String, String> userInfo;
      if (userDoc.exists) {
        userInfo = {
          'name': userDoc['name'] ?? 'Unknown',
          'image': userDoc['profilePicture'] ?? 'assets/images/profile.png',
          'phone': userDoc['phoneNumber'] ?? '',
        };
      } else {
        userInfo = {
          'name': 'Unknown',
          'image': 'assets/images/profile.png',
          'phone': '',
        };
      }

      // Store in cache
      _userCache[userId] = userInfo;
      return userInfo;
    } catch (e) {
      print('Error fetching user info: $e');
      final errorInfo = {
        'name': 'Unknown',
        'image': 'assets/images/profile.png',
        'phone': '',
      };
      _userCache[userId] = errorInfo;
      return errorInfo;
    }
  }

  Future<void> _showAddMenu(BuildContext context) async {
    final RenderBox button =
        _iconKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    return showMenu(
      context: context,
      position: position,
      color: const Color(0xff4a4b62),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Friendlist()),
              );
            });
          },
          child: Row(
            children: const [
              Icon(Icons.person, color: Color(0xff9A9BB1), size: 30),
              SizedBox(width: 10),
              Text(
                "Add Friend",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Addgroup()),
              );
            });
          },
          child: Row(
            children: const [
              Icon(Icons.groups_2, color: Color(0xff9A9BB1), size: 30),
              SizedBox(width: 10),
              Text(
                "Create Group",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSkeleton(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.grey[800]),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: size.width * 0.4,
                height: 16,
                color: Colors.grey[800],
              ),
              SizedBox(height: 8),
              Container(
                width: size.width * 0.3,
                height: 12,
                color: Colors.grey[800],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
