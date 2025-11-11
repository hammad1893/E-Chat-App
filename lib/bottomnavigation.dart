import 'package:chat_app/Aichatintegration/chatwithgemini.dart';
import 'package:chat_app/folder/groupscreen.dart';
import 'package:chat_app/homepage.dart/homescreen.dart';
import 'package:chat_app/profilescreens/profilepage.dart';
import 'package:chat_app/state/unread_count_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int currentIndex = 0;

  final List<Map<String, dynamic>> navItems = [
    {
      "icon": Icons.chat_bubble,
      "label": "Chats",
      "showBadge": true,
      "badgeType": "individual",
    },
    {
      "icon": Icons.group_outlined,
      "label": "Groups",
      "showBadge": true,
      "badgeType": "group",
    },
    {"icon": Icons.person_outline, "label": "Profile", "showBadge": false},
  ];

  final List<Widget> screens = const [
    Homescreen(),
    Groupscreen(),
    Profilepage(),
  ];

  // Method to check if FAB should be visible
  bool get _isFabVisible {
    // Show FAB only on HomeScreen (index 0) and GroupScreen (index 1)
    return currentIndex == 0 || currentIndex == 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF292929),
      body: screens[currentIndex],
      bottomNavigationBar: Consumer<UnreadCountProvider>(
        builder: (context, unreadProvider, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2B2B3A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                bool isSelected = index == currentIndex;
                final item = navItems[index];

                // Get unread count for this tab
                int unreadCount = 0;
                if (item['showBadge'] == true) {
                  if (item['badgeType'] == 'individual') {
                    unreadCount = unreadProvider.individualUnreadCount;
                  } else if (item['badgeType'] == 'group') {
                    unreadCount = unreadProvider.groupUnreadCount;
                  }
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: isSelected
                            ? BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF40C4FF),
                                    Color(0xFF17A1FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              )
                            : null,
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Icon(
                                  item["icon"],
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[400],
                                ),
                                // Show badge only if there are unread messages
                                if (unreadCount > 0 &&
                                    item['showBadge'] == true)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 12,
                                        minHeight: 12,
                                      ),
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Text(
                                item["label"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        },
      ),
      // Conditionally show FAB based on current screen
      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF40C4FF),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AiChatScreen()),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
            )
          : null,
    );
  }
}