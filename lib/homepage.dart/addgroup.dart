
// screens/add_group_screen.dart
import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/folder/groupchat.dart';
import 'package:chat_app/model/authmodel.dart';
import 'package:chat_app/state/authstate.dart';
import 'package:chat_app/state/groupstate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Addgroup extends StatefulWidget {
  const Addgroup({super.key});

  @override
  State<Addgroup> createState() => _AddgroupState();
}

class _AddgroupState extends State<Addgroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late List<bool> isCheckedList;
  List<AuthModel> selectedMembers = [];
  List<AuthModel> allUsers = [];
  List<AuthModel> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(allUsers);
      } else {
        filteredUsers =
            allUsers.where((user) {
              final name = user.name?.toLowerCase() ?? '';
              final phone = user.phoneNumber?.toLowerCase() ?? '';
              return name.contains(query) || phone.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _loadUsers() async {
    final authState = Provider.of<Authstate>(context, listen: false);
    final currentUser = authState.usermodel;

    if (currentUser == null) return;

    // Fetch all users from Firebase (excluding current user)
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('id', isNotEqualTo: currentUser.id)
              .get();

      setState(() {
        allUsers =
            usersSnapshot.docs
                .map((doc) => AuthModel.fromJson(doc.data()))
                .toList();
        filteredUsers = List.from(allUsers);
        isCheckedList = List<bool>.filled(allUsers.length, false);
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      SnackbarMessage.failedsnack("Group name cannot be empty", context);
      return;
    }

    if (selectedMembers.isEmpty) {
      SnackbarMessage.failedsnack("Please select at least one member", context);
      return;
    }

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final authState = Provider.of<Authstate>(context, listen: false);
    final currentUser = authState.usermodel;

    if (currentUser == null) return;

    try {
      final memberIds = selectedMembers.map((user) => user.id!).toList();

      final groupId = await groupProvider.createGroup(
        name: _groupNameController.text,
        memberIds: memberIds,
      );

      // Navigate to group chat screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => GroupChatScreen(
                groupId: groupId,
                groupName: _groupNameController.text,
              ),
        ),
      );
    } catch (e) {
      SnackbarMessage.failedsnack("Error creating group: $e", context);
      print('Error creating group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xff292929),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Color(0xff135CAF),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xff2a6cb7),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        title: Text(
          "Add Group",
          style: Apptexts.titlestyle.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * .04),
              Text(
                "Group Name",
                style: Apptexts.bodystyle.copyWith(color: Color(0xffD0D1DB)),
              ),
              SizedBox(height: size.height * .01),
              TextField(
                style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
                controller: _groupNameController,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  label: Text(
                    "Enter Group Name",
                    style: Apptexts.bodystyle.copyWith(
                      color: Color(0xffF0F0F3),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xff9A9BB1), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xff9A9BB1), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xff9A9BB1), width: 2),
                  ),
                ),
              ),
              SizedBox(height: size.height * .025),
              Text(
                "Members",
                style: Apptexts.bodystyle.copyWith(color: Color(0xffD0D1DB)),
              ),
              SizedBox(height: size.height * .01),
              SizedBox(
                height: size.height * .06,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffECF9FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showAddMembersSheet(context);
                  },
                  icon: Icon(Icons.add, color: Color(0xff135CAF), size: 30),
                  label: Text(
                    "Add Members to group ",
                    style: Apptexts.subtitlestyle.copyWith(
                      color: Color(0xff135CAF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (selectedMembers.isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  children:
                      selectedMembers.map((member) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              member.profilePicture ??
                                  'https://i.pravatar.cc/100?img=1',
                            ),
                          ),
                          title: Text(
                            member.name ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            member.phoneNumber ?? '',
                            style: const TextStyle(color: Color(0xff9A9BB1)),
                          ),
                          trailing: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Color(0xff545454),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedMembers.remove(member);
                                  int idx = allUsers.indexWhere(
                                    (u) => u.id == member.id,
                                  );
                                  if (idx >= 0) isCheckedList[idx] = false;
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
              SizedBox(height: size.height * .04),
              SizedBox(
                height: size.height * .065,
                child: ElevatedButton(
                  onPressed: _createGroup,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff40C4FF), Color(0xff03A9F4)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Create Group',
                        style: Apptexts.titlestyle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * .02),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMembersSheet(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Text(
                          "Add members to group",
                          style: TextStyle(
                            color: Color(0xffF0F0F3),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: size.height * .02),
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            cursorColor: Color(0xffF0F0F3),
                            decoration: InputDecoration(
                              hintText: "Search",
                              hintStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xffD0D1DB),
                              ),
                              filled: true,
                              fillColor: Color(0xff686A8A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setModalState(() {
                                // The _filterUsers method will be called automatically
                                // because we added a listener to _searchController
                              });
                            },
                          ),
                        ),
                        SizedBox(height: size.height * .01),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            controller: controller,
                            itemCount: filteredUsers.length,
                            itemBuilder: (_, index) {
                              final member = filteredUsers[index];
                              final originalIndex = allUsers.indexWhere(
                                (user) => user.id == member.id,
                              );
                              final isChecked =
                                  originalIndex >= 0
                                      ? isCheckedList[originalIndex]
                                      : false;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    member.profilePicture ??
                                        'https://i.pravatar.cc/100?img=1',
                                  ),
                                ),
                                title: Text(
                                  member.name ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  member.phoneNumber ?? '',
                                  style: const TextStyle(
                                    color: Color(0xff9A9BB1),
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    setModalState(() {
                                      if (originalIndex >= 0) {
                                        isCheckedList[originalIndex] =
                                            value ?? false;

                                        if (value == true) {
                                          selectedMembers.add(member);
                                        } else {
                                          selectedMembers.remove(member);
                                        }
                                      }
                                    });
                                  },
                                  activeColor: Colors.blue,
                                  checkColor: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: Colors.white30),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: Color(0xff3AB2E8)),
                                  ),
                                ),
                              ),
                              SizedBox(width: size.width * .02),
                              Expanded(
                                child: SizedBox(
                                  height: size.height * .06,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        // Update the main screen state with selected members
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xff40C4FF),
                                            Color(0xff03A9F4),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Add',
                                          style: Apptexts.titlestyle.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
        );
      },
    );
  }
}
