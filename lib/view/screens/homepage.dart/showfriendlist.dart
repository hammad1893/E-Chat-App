import 'package:chat_app/view/constants/text.dart';
import 'package:chat_app/view/screens/homepage.dart/addcontact.dart';
import 'package:chat_app/view/screens/homepage.dart/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class Friendlist extends StatefulWidget {
  const Friendlist({super.key});

  @override
  State<Friendlist> createState() => _FriendlistState();
}

class _FriendlistState extends State<Friendlist> {
  bool isSearching = false;
  String searchQuery = "";
  bool contactsPermissionGranted = false;
  bool contactsLoaded = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    PermissionStatus status = await Permission.contacts.status;

    if (status.isGranted) {
      setState(() {
        contactsPermissionGranted = true;
      });
      _askAndSaveContacts();
    } else {
      status = await Permission.contacts.request();

      if (status.isGranted) {
        setState(() {
          contactsPermissionGranted = true;
        });
        _askAndSaveContacts();
      } else {
        setState(() {
          contactsPermissionGranted = false;
        });
        _handleInvalidPermissions(status);
      }
    }
  }

  /// ✅ Improved phone number normalization
  String normalizePhone(String phone) {
    if (phone.isEmpty) return "";

    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove country code for comparison
    if (normalized.startsWith('+92')) {
      normalized = normalized.substring(3);
    } else if (normalized.startsWith('92')) {
      normalized = normalized.substring(2);
    }

    // For Pakistan numbers starting with 0
    if (normalized.startsWith('0')) {
      normalized = normalized.substring(1);
    }

    // Remove any remaining non-digit characters
    normalized = normalized.replaceAll(RegExp(r'[^\d]'), '');

    return normalized;
  }

  /// ✅ Format phone number for display
  String formatPhoneForDisplay(String phone) {
    if (phone.isEmpty) return "";

    if (phone.length == 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }

    return phone;
  }

  Future<void> _askAndSaveContacts() async {
    if (!contactsPermissionGranted) return;

    try {
      List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      final userId = _auth.currentUser!.uid;
      final userContactsRef = _firestore
          .collection("users")
          .doc(userId)
          .collection("contacts");

      WriteBatch batch = _firestore.batch();

      for (var contact in contacts) {
        if (contact.phones.isNotEmpty) {
          for (var phone in contact.phones) {
            final rawPhone = phone.number;
            final normalizedPhone = normalizePhone(rawPhone);

            if (normalizedPhone.isNotEmpty) {
              final docRef = userContactsRef.doc(normalizedPhone);

              batch.set(docRef, {
                "name": contact.displayName,
                "phone": normalizedPhone,
                "rawPhone": rawPhone,
                "image": null,
                "lastUpdated": FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      await batch.commit();

      setState(() {
        contactsLoaded = true;
      });
    } catch (e) {
      print("Error saving contacts: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error accessing contacts')));
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access to contact data denied')),
      );
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contact data not available on device. Please enable in settings.',
          ),
        ),
      );
      openAppSettings();
    }
  }

  Stream<QuerySnapshot> _getRegisteredUserStream(String phoneNumber) {
    String normalizedPhone = normalizePhone(phoneNumber);

    return _firestore
        .collection("users")
        .where("phoneNumber", isEqualTo: normalizedPhone)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final userId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xff292929),
      body: Column(
        children: [
          _buildTopBar(size),
          SizedBox(height: size.height * .06),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: size.height * .06,
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffECF9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Addcontact()),
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xff135CAF), size: 30),
                label: Text(
                  "Add Friend ",
                  style: Apptexts.subtitlestyle.copyWith(
                    color: const Color(0xff135CAF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          if (!contactsPermissionGranted)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Contacts permission required to sync friends",
                style: TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),

          SizedBox(height: size.height * .04),

          Expanded(
            child: StreamBuilder(
              stream:
                  _firestore
                      .collection("users")
                      .doc(userId)
                      .collection("contacts")
                      .orderBy("name")
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var contacts = snapshot.data!.docs;

                if (searchQuery.isNotEmpty) {
                  final normalizedQuery = normalizePhone(searchQuery);
                  final lowerCaseQuery = searchQuery.toLowerCase();

                  contacts =
                      contacts.where((doc) {
                        final data = doc.data();
                        final name =
                            (data["name"] ?? "").toString().toLowerCase();
                        final phone = (data["phone"] ?? "").toString();
                        final rawPhone =
                            (data["rawPhone"] ?? "").toString().toLowerCase();

                        if (name.contains(lowerCaseQuery)) {
                          return true;
                        }

                        if (normalizedQuery.isNotEmpty &&
                            phone.contains(normalizedQuery)) {
                          return true;
                        }

                        if (rawPhone.contains(lowerCaseQuery)) {
                          return true;
                        }

                        return false;
                      }).toList();
                }

                if (contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          contactsPermissionGranted
                              ? "No contacts found"
                              : "Contacts permission required",
                          style: TextStyle(color: Colors.white),
                        ),
                        if (!contactsPermissionGranted)
                          TextButton(
                            onPressed: _checkAndRequestPermissions,
                            child: Text(
                              "Grant Permission",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final data = contacts[index].data();
                    final name = data["name"] ?? "";
                    final phone = data["phone"] ?? "";
                    final rawPhone = data["rawPhone"] ?? phone;

                    final String? firstLetter =
                        name.isNotEmpty ? name[0].toUpperCase() : null;
                    final displayName =
                        name.isNotEmpty
                            ? name
                            : formatPhoneForDisplay(rawPhone);
                    final displayPhone = formatPhoneForDisplay(rawPhone);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xff135CAF),
                        child:
                            firstLetter != null
                                ? Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        displayPhone,
                        style: const TextStyle(color: Color(0xff9A9BB1)),
                      ),
                      trailing: StreamBuilder<QuerySnapshot>(
                        stream: _getRegisteredUserStream(phone),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Icon(Icons.error, color: Colors.red);
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final isRegistered = docs.isNotEmpty;

                          if (isRegistered) {
                            final userDoc = docs.first;
                            final chatUserId = userDoc.id;

                            if (chatUserId == userId) {
                              return const SizedBox.shrink();
                            }

                            return IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => Chatscreen(
                                          name: name,
                                          image:
                                              userDoc['profilePicture'] ??
                                              "assets/images/default.png",
                                          receiverId: chatUserId,
                                          phone: phone,
                                          senderId: userId,
                                        ),
                                  ),
                                );
                              },
                            );
                          } else {
                            // Simple Invite Button
                            return TextButton(
                              onPressed: () => _inviteContact(phone, name),
                              child: Text(
                                "Invite",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }
                        },
                      ),
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

  void _inviteContact(String phone, String contactName) async {
  try {
    print("📱 Starting invite process for $contactName ($phone)");

    final userId = _auth.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Your friend';

    // Store in Firebase first
    print("💾 Storing invite in Firebase...");
    await _firestore.collection('invites').add({
      'fromUserId': userId,
      'fromUserName': userName,
      'toPhone': phone,
      'toContactName': contactName,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    print("✅ Invite stored in Firebase");

    // Create SMS message with your APK download link
    final message =
        "Hi $contactName! $userName invited you to join ChatApp. Download the app here: https://yourapkdownloadlink.com/app.apk";

    // Create SMS URL
    final smsUrl = 'sms:${phone.trim()}?body=${Uri.encodeComponent(message)}';
    
    print("📤 Launching SMS app: $smsUrl");

    // Launch SMS app
    if (await canLaunchUrl(Uri.parse(smsUrl))) {
      await launchUrl(Uri.parse(smsUrl));
      print("✅ SMS app launched successfully");
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite sent to $contactName!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print("❌ Cannot launch SMS app");
      throw 'Cannot open SMS app';
    }

  } catch (e) {
    print('💥 Error in _inviteContact: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send invite: $e'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

  Widget _buildTopBar(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * .14,
      decoration: BoxDecoration(
        color: const Color(0xff135CAF),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(size.width * 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 40, right: 20),
        child: isSearching ? _buildSearchBar() : _buildHeader(size),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              cursorColor: const Color(0xff135CAF),
              decoration: InputDecoration(
                hintText: 'Search by name or number...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              style: Apptexts.bodystyle.copyWith(color: Colors.black),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
            onPressed: () {
              setState(() {
                isSearching = false;
                searchQuery = "";
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: size.height * .07,
            width: size.width * .13,
            decoration: const BoxDecoration(
              color: Color(0xff2a6cb7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        Text(
          "Add Friends",
          style: Apptexts.titlestyle.copyWith(color: Colors.white),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 30),
          onPressed: () {
            setState(() {
              isSearching = true;
            });
          },
        ),
      ],
    );
  }
}
