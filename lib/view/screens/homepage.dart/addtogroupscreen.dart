import 'package:chat_app/model/groupmodel.dart';
import 'package:chat_app/view_model/groupstate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupSelectionScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String contactImageUrl;

  const GroupSelectionScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactImageUrl,
  });

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  List<ChatGroup> _groups = [];
  List<String> _selectedGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final allGroups = await groupProvider.getUserGroups().first;

      // Properly filter groups where:
      // 1. Current user is admin
      // 2. Contact is NOT already a member
      final currentUserId = _getCurrentUserId();
      final filteredGroups =
          allGroups.where((group) {
            final isCurrentUserAdmin = group.adminIds.contains(currentUserId);
            final isContactAlreadyMember = group.memberIds.contains(
              widget.contactId,
            );

            // Only include groups where user is admin AND contact is not already a member
            return isCurrentUserAdmin && !isContactAlreadyMember;
          }).toList();

      setState(() {
        _groups = filteredGroups;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _addToGroups() async {
    if (_selectedGroups.isEmpty) return;

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              backgroundColor: const Color(0xff3e3e3e),
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Adding to groups...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
      );

      // Add to selected groups
      for (final groupId in _selectedGroups) {
        await groupProvider.addMembersToGroup(groupId, [widget.contactId]);
      }

      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${widget.contactName} to ${_selectedGroups.length} group(s)',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Return to previous screen with success result
      Navigator.pop(context, true);
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to groups: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff292929),
      appBar: AppBar(
        backgroundColor: const Color(0xff292929),
        title: Text(
          'Add ${widget.contactName} to Group',
          style: TextStyle(color: Colors.white, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedGroups.isNotEmpty)
            TextButton(
              onPressed: _addToGroups,
              child: Text(
                'ADD (${_selectedGroups.length})',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading groups...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
              : _groups.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No groups available',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Either you\'re not an admin of any groups, or ${widget.contactName} is already in all your groups.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  // Header with contact info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xff3e3e3e),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade700),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              widget.contactImageUrl.isNotEmpty
                                  ? NetworkImage(widget.contactImageUrl)
                                  : null,
                          child:
                              widget.contactImageUrl.isEmpty
                                  ? Text(
                                    widget.contactName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(color: Colors.white),
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.contactName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Select groups to add this contact',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Groups list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return _buildGroupItem(group);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildGroupItem(ChatGroup group) {
    final isSelected = _selectedGroups.contains(group.groupId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Color(0xff3e3e3e),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade700,
          backgroundImage:
              group.imageUrl != null && group.imageUrl!.isNotEmpty
                  ? NetworkImage(group.imageUrl!)
                  : null,
          child:
              group.imageUrl == null || group.imageUrl!.isEmpty
                  ? Text(
                    group.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        title: Text(
          group.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${group.memberIds.length} members • You are admin',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.blue : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
              width: 2,
            ),
          ),
          child: Icon(
            isSelected ? Icons.check : Icons.add,
            color: isSelected ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedGroups.remove(group.groupId);
            } else {
              _selectedGroups.add(group.groupId);
            }
          });
        },
      ),
    );
  }
}
