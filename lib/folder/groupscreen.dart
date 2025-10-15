import 'package:chat_app/constants/text.dart';
import 'package:chat_app/folder/groupchat.dart';
import 'package:chat_app/homepage.dart/addgroup.dart';
import 'package:chat_app/homepage.dart/showfriendlist.dart';
import 'package:chat_app/model/groupmodel.dart';
import 'package:chat_app/state/groupstate.dart';
import 'package:chat_app/state/unread_count_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Groupscreen extends StatefulWidget {
  const Groupscreen({super.key});

  @override
  State<Groupscreen> createState() => _GroupscreenState();
}

class _GroupscreenState extends State<Groupscreen> {
  bool isclicked = false;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _iconKey = GlobalKey();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xff292929),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            height: size.height * .14,
            decoration: const BoxDecoration(
              color: Color(0xff135CAF),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
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
                                cursorColor: const Color(0xff135CAF),
                                decoration: InputDecoration(
                                  hintText: 'Search groups...',
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintStyle: const TextStyle(
                                    color: Color(0xff9A9BB1),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xff9A9BB1),
                                  ),
                                ),
                                style: Apptexts.bodystyle.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    isSearching = false;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                }
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
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  isSearching = true;
                                });
                              }
                            },
                          ),
                          IconButton(
                            key: _iconKey,
                            icon:
                                isclicked
                                    ? const Icon(
                                      Icons.cancel,
                                      color: Colors.white,
                                      size: 32,
                                    )
                                    : const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            onPressed: () async {
                              if (!isclicked) {
                                if (mounted) {
                                  setState(() => isclicked = true);
                                }
                                await _showAddMenu(context);
                                if (mounted) {
                                  setState(() => isclicked = false);
                                }
                              } else {
                                if (mounted) {
                                  setState(() => isclicked = false);
                                }
                              }
                            },
                          ),
                        ],
                      ),
            ),
          ),

          // Groups List
          Expanded(
            child: Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                return StreamBuilder<List<ChatGroup>>(
                  stream: groupProvider.getUserGroups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState(size);
                    }

                    if (snapshot.hasError) {
                      print('Group stream error: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading groups',
                              style: Apptexts.bodystyle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your connection',
                              style: Apptexts.bodystyle.copyWith(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          'No data received',
                          style: Apptexts.bodystyle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    final groups = snapshot.data ?? [];
                    final filteredGroups =
                        _searchQuery.isEmpty
                            ? groups
                            : groups
                                .where(
                                  (group) => group.name.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                                )
                                .toList();

                    if (filteredGroups.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No groups yet'
                              : 'No groups found',
                          style: Apptexts.bodystyle.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 10),
                      itemCount: filteredGroups.length,
                      itemBuilder: (BuildContext context, int index) {
                        final group = filteredGroups[index];
                        return _buildGroupListItem(
                          context,
                          group,
                          size,
                          currentUserId,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (Keep _showAddMenu method as is)

  Widget _buildGroupListItem(
    BuildContext context,
    ChatGroup group,
    Size size,
    String? currentUserId,
  ) {
    if (group.groupId.isEmpty) {
      return const SizedBox();
    }

    return StreamBuilder<int>(
      stream: Provider.of<UnreadCountProvider>(
        context,
        listen: false,
      ).getChatUnreadCount(group.groupId),
      builder: (context, unreadSnapshot) {
        final unreadCount = unreadSnapshot.data ?? 0;

        return _buildGroupListItemContent(
          context,
          group,
          size,
          currentUserId,
          unreadCount,
        );
      },
    );
  }

  Widget _buildGroupListItemContent(
    BuildContext context,
    ChatGroup group,
    Size size,
    String? currentUserId,
    int unreadCount,
  ) {
    return InkWell(
      onTap: () {
        _navigateToGroupChat(context, group);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xff3a3a3a),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xff40C4FF),
              backgroundImage:
                  group.imageUrl != null &&
                          group.imageUrl!.isNotEmpty &&
                          group.imageUrl!.startsWith('http')
                      ? CachedNetworkImageProvider(group.imageUrl!)
                      : null,
              child:
                  group.imageUrl == null ||
                          group.imageUrl!.isEmpty ||
                          !group.imageUrl!.startsWith('http')
                      ? Text(
                        group.name.isNotEmpty && group.name != 'null'
                            ? group.name[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name.isNotEmpty && group.name != 'null'
                        ? group.name
                        : 'Unnamed Group',
                    style: Apptexts.titlestyle.copyWith(
                      color: Colors.white,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      fontSize: size.width * .045,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSafeLastMessage(group.lastMessage),
                    style: Apptexts.bodystyle.copyWith(
                      color:
                          unreadCount > 0
                              ? Colors.white
                              : const Color(0xff9A9BB1),
                      fontWeight:
                          unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      fontSize: size.width * .035,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  _formatLastActive(group.lastMessageTime ?? group.createdAt),
                  style: Apptexts.bodystyle.copyWith(
                    color: const Color(0xff9A9BB1),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                if (unreadCount > 0)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xff40C4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: Apptexts.bodystyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Simplified navigation - let GroupChatScreen handle marking as read
  void _navigateToGroupChat(BuildContext context, ChatGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GroupChatScreen(
              groupId: group.groupId,
              groupName: group.name,
              groupImage: group.imageUrl ?? '',
              memberCount: group.memberIds.length,
            ),
      ),
    );
  }

  // Helper method to safely get last message
  String _getSafeLastMessage(String? lastMessage) {
    if (lastMessage == null || lastMessage.isEmpty || lastMessage == 'null') {
      return 'No messages yet';
    }
    return lastMessage;
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
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Friendlist()),
                );
              }
            });
          },
          child: const Row(
            children: [
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
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Addgroup()),
                );
              }
            });
          },
          child: const Row(
            children: [
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

  // Skeleton loading widget
  // Widget _buildGroupListItemSkeleton(Size size) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  //     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: const Color(0xff3a3a3a),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 50,
  //           height: 50,
  //           decoration: BoxDecoration(
  //             color: Colors.grey[700],
  //             borderRadius: BorderRadius.circular(25),
  //           ),
  //         ),
  //         const SizedBox(width: 15),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Container(
  //                 width: size.width * 0.4,
  //                 height: 16,
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[700],
  //                   borderRadius: BorderRadius.circular(4),
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Container(
  //                 width: size.width * 0.3,
  //                 height: 12,
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[700],
  //                   borderRadius: BorderRadius.circular(4),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Column(
  //           children: [
  //             Container(
  //               width: 30,
  //               height: 12,
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[700],
  //                 borderRadius: BorderRadius.circular(4),
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Container(
  //               width: 20,
  //               height: 20,
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[700],
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLoadingState(Size size) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xff3a3a3a),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: size.width * 0.4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: size.width * 0.3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatLastActive(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}
