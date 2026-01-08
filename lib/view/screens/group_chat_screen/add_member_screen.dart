import 'package:chat_app/view_model/groupstate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AddMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final List<Map<String, dynamic>> _selectedMembers = [];
  final List<Map<String, dynamic>> _allContacts = [];
  bool _isLoading = true;
  bool _isAddingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      // Get the first snapshot of available contacts
      final contacts =
          await groupProvider.getAvailableContacts(widget.groupId).first;

      setState(() {
        _allContacts.clear();
        _allContacts.addAll(contacts);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading contacts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleMemberSelection(Map<String, dynamic> member) {
    setState(() {
      final isSelected = _selectedMembers.any((m) => m['uid'] == member['uid']);

      if (isSelected) {
        _selectedMembers.removeWhere((m) => m['uid'] == member['uid']);
      } else {
        _selectedMembers.add(member);
      }

      // Update selection state in the list
      final index = _allContacts.indexWhere((m) => m['uid'] == member['uid']);
      if (index != -1) {
        _allContacts[index]['isSelected'] = !isSelected;
      }
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAddingMembers = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final selectedIds =
          _selectedMembers.map((member) => member['uid'] as String).toList();

      await groupProvider.addMembersToGroupWithSelection(
        widget.groupId,
        selectedIds,
      );

      // Success - go back
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedMembers.length} member(s) added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isAddingMembers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding members: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMemberList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allContacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts available to add',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _allContacts.length,
      itemBuilder: (context, index) {
        final member = _allContacts[index];
        final isSelected = _selectedMembers.any(
          (m) => m['uid'] == member['uid'],
        );

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                member['photoUrl'] != null
                    ? NetworkImage(member['photoUrl'])
                    : null,
            child:
                member['photoUrl'] == null
                    ? Text(
                      (member['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                    : null,
          ),
          title: Text(
            member['name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            member['phone']?.isNotEmpty == true
                ? member['phone']
                : (member['email'] ?? ''),
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: 2,
              ),
              color: isSelected ? Colors.blue : Colors.transparent,
            ),
            child:
                isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
          ),
          onTap: () => _toggleMemberSelection(member),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff292929),
      appBar: AppBar(
        backgroundColor: const Color(0xff292929),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Members', style: TextStyle(color: Colors.white)),
            Text(
              '${_selectedMembers.length} selected',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedMembers.isNotEmpty)
            IconButton(
              icon:
                  _isAddingMembers
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check, color: Colors.white),
              onPressed: _isAddingMembers ? null : _addSelectedMembers,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xff3e3e3e),
                hintText: 'Search contacts...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
              },
            ),
          ),
          Expanded(child: _buildMemberList()),
        ],
      ),
    );
  }
}
