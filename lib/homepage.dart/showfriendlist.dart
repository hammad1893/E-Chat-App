// import 'package:chat_app/constants/text.dart';
// import 'package:chat_app/homepage.dart/addcontact.dart';
// import 'package:flutter/material.dart';

// class Friendlist extends StatefulWidget {
//   const Friendlist({super.key});

//   @override
//   State<Friendlist> createState() => _FriendlistState();
// }

// class _FriendlistState extends State<Friendlist> {
//   List members = [
//     {
//       "name": "Erin Turcotte",
//       "phone": "+61 362 901 559",
//       "image": "https://i.pravatar.cc/100?img=7",
//     },
//     {
//       "name": "Rodolfo Walter",
//       "phone": "+1 529 100 2355",
//       "image": "https://i.pravatar.cc/100?img=8",
//     },
//     38593,
//   ];

//   bool isSearching = false;
//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: Color(0xff292929),
//       body: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             height: size.height * .14,
//             decoration: BoxDecoration(
//               color: Color(0xff135CAF),
//               borderRadius: BorderRadius.only(
//                 bottomRight: Radius.circular(size.width * 0.1),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.only(top: 40, right: 20),
//               child:
//                   isSearching
//                       ? Padding(
//                         padding: const EdgeInsets.only(left: 20, right: 10),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 cursorColor: Color(0xff135CAF),
//                                 decoration: InputDecoration(
//                                   hintText: 'Search...',

//                                   fillColor: Colors.white,
//                                   filled: true,
//                                   hintStyle: TextStyle(
//                                     color: Color(0xff9A9BB1),
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(20),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                 ),
//                                 style: Apptexts.bodystyle.copyWith(
//                                   color: Colors.black,
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               icon: Icon(
//                                 Icons.cancel,
//                                 color: Colors.white,
//                                 size: 30,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   isSearching = false;
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                       )
//                       : Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           InkWell(
//                             onTap: () => Navigator.pop(context),
//                             child: Container(
//                               margin: EdgeInsets.symmetric(horizontal: 10),
//                               height: size.height * .07,
//                               width: size.width * .13,
//                               decoration: BoxDecoration(
//                                 color: Color(0xff2a6cb7),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.arrow_back,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             "Add Friends",
//                             style: Apptexts.titlestyle.copyWith(
//                               color: Colors.white,
//                             ),
//                           ),

//                           IconButton(
//                             icon: Icon(
//                               Icons.search,
//                               color: Colors.white,
//                               size: 30,
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 isSearching = true;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//             ),
//           ),
//           SizedBox(height: size.height * .04),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: SizedBox(
//               height: size.height * .06,
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xffECF9FF),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => Addcontact()),
//                   );
//                 },
//                 icon: Icon(Icons.add, color: Color(0xff135CAF), size: 30),
//                 label: Text(
//                   "Add Friend ",
//                   style: Apptexts.subtitlestyle.copyWith(
//                     color: Color(0xff135CAF),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: size.height * .03),
//           ListView.builder(
//             shrinkWrap: true,
//             itemCount: members.length,
//             itemBuilder: (BuildContext context, int index) {
//               Map member = members[index];
//               return ListTile(
//                 leading: CircleAvatar(
//                   backgroundImage: NetworkImage(members[index]["image"]!),
//                 ),
//                 title: Text(
//                   member["name"]!,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 subtitle: Text(
//                   member["phone"]!,
//                   style: const TextStyle(color: Color(0xff9A9BB1)),
//                 ),
//                 trailing: IconButton(
//                   icon: Image.asset("assets/images/bbuton.png"),
//                   onPressed: () {},
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:chat_app/constants/text.dart';
// import 'package:chat_app/homepage.dart/addcontact.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';
// import 'package:permission_handler/permission_handler.dart';

// class Friendlist extends StatefulWidget {
//   const Friendlist({super.key});

//   @override
//   State<Friendlist> createState() => _FriendlistState();
// }

// class _FriendlistState extends State<Friendlist> {
//   bool isSearching = false;

//   @override
//   void initState() {
//     super.initState();
//     _askAndSaveContacts();
//   }
//   Future<void> _askAndSaveContacts() async {
//     PermissionStatus permissionStatus = await _getContactPermission();
//     if (permissionStatus == PermissionStatus.granted) {
//       // Load contacts with properties (phones, emails, etc.)
//       List<Contact> contacts = await FlutterContacts.getContacts(
//         withProperties: true,
//       );

//       final userId = FirebaseAuth.instance.currentUser!.uid;
//       final userContactsRef = FirebaseFirestore.instance
//           .collection("users")
//           .doc(userId)
//           .collection("contacts");

//       WriteBatch batch = FirebaseFirestore.instance.batch();

//       for (var contact in contacts) {
//         if (contact.phones.isNotEmpty) {
//           final phone = contact.phones.first.number;
//           final docRef = userContactsRef.doc(phone);

//           batch.set(docRef, {
//             "name": contact.displayName,
//             "phone": phone,
//             "image": null,
//           });
//         }
//       }

//       await batch.commit();
//     } else {
//       _handleInvalidPermissions(permissionStatus);
//     }
//   }

//   Future<PermissionStatus> _getContactPermission() async {
//     PermissionStatus permission = await Permission.contacts.status;
//     if (permission != PermissionStatus.granted &&
//         permission != PermissionStatus.permanentlyDenied) {
//       return await Permission.contacts.request();
//     } else {
//       return permission;
//     }
//   }

//   void _handleInvalidPermissions(PermissionStatus permissionStatus) {
//     if (permissionStatus == PermissionStatus.denied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Access to contact data denied')),
//       );
//     } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Contact data not available on device')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     final userId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       backgroundColor: const Color(0xff292929),
//       body: Column(
//         children: [
//           /// 🔹 Top Bar
//           _buildTopBar(size),

//           SizedBox(height: size.height * .04),

//           /// 🔹 Add Friend Button
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: SizedBox(
//               height: size.height * .06,
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xffECF9FF),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => Addcontact()),
//                   );
//                 },
//                 icon: const Icon(Icons.add, color: Color(0xff135CAF), size: 30),
//                 label: Text(
//                   "Add Friend ",
//                   style: Apptexts.subtitlestyle.copyWith(
//                     color: const Color(0xff135CAF),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           SizedBox(height: size.height * .03),
//           Expanded(
//             child: StreamBuilder(
//               stream:
//                   FirebaseFirestore.instance
//                       .collection("users")
//                       .doc(userId)
//                       .collection("contacts")
//                       .orderBy("name")
//                       .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 var contacts = snapshot.data!.docs;

//                 if (contacts.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       "No contacts found",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: contacts.length,
//                   itemBuilder: (context, index) {
//                     final name = contacts[index]["name"] ?? "";
//                     final firstLetter =
//                         name.isNotEmpty ? name[0].toUpperCase() : null;
//                     return ListTile(
//                       leading: CircleAvatar(
//                         child:
//                             firstLetter != null
//                                 ? Text(
//                                   firstLetter,
//                                   style: const TextStyle(
//                                     color: Color(0xff135CAF),
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 )
//                                 : const Icon(Icons.person, color: Colors.white),
//                       ),
//                       title: Text(
//                         contacts[index]["name"],
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Text(
//                         contacts[index]["phone"],
//                         style: const TextStyle(color: Color(0xff9A9BB1)),
//                       ),
//                       trailing: IconButton(
//                         icon: Image.asset("assets/images/bbuton.png"),
//                         onPressed: () {},
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 🔹 Top Bar Widgets
//   Widget _buildTopBar(Size size) {
//     return Container(
//       width: double.infinity,
//       height: size.height * .14,
//       decoration: BoxDecoration(
//         color: const Color(0xff135CAF),
//         borderRadius: BorderRadius.only(
//           bottomRight: Radius.circular(size.width * 0.1),
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.only(top: 40, right: 20),
//         child: isSearching ? _buildSearchBar() : _buildHeader(size),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.only(left: 20, right: 10),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               cursorColor: const Color(0xff135CAF),
//               decoration: InputDecoration(
//                 hintText: 'Search...',
//                 fillColor: Colors.white,
//                 filled: true,
//                 hintStyle: const TextStyle(color: Color(0xff9A9BB1)),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//               style: Apptexts.bodystyle.copyWith(color: Colors.black),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
//             onPressed: () {
//               setState(() {
//                 isSearching = false;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(Size size) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         InkWell(
//           onTap: () => Navigator.pop(context),
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 10),
//             height: size.height * .07,
//             width: size.width * .13,
//             decoration: const BoxDecoration(
//               color: Color(0xff2a6cb7),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.arrow_back, color: Colors.white),
//           ),
//         ),
//         Text(
//           "Add Friends",
//           style: Apptexts.titlestyle.copyWith(color: Colors.white),
//         ),
//         IconButton(
//           icon: const Icon(Icons.search, color: Colors.white, size: 30),
//           onPressed: () {
//             setState(() {
//               isSearching = true;
//             });
//           },
//         ),
//       ],
//     );
//   }
// }

// import 'package:chat_app/constants/text.dart';
// import 'package:chat_app/homepage.dart/addcontact.dart';
// import 'package:chat_app/homepage.dart/chatscreen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';
// import 'package:permission_handler/permission_handler.dart';

// class Friendlist extends StatefulWidget {
//   const Friendlist({super.key});

//   @override
//   State<Friendlist> createState() => _FriendlistState();
// }

// class _FriendlistState extends State<Friendlist> {
//   bool isSearching = false;
//   String searchQuery = "";

//   @override
//   void initState() {
//     super.initState();
//     _askAndSaveContacts();
//   }

//   Future<void> _askAndSaveContacts() async {
//     PermissionStatus permissionStatus = await _getContactPermission();
//     if (permissionStatus == PermissionStatus.granted) {
//       // Load contacts with properties (phones, emails, etc.)
//       List<Contact> contacts = await FlutterContacts.getContacts(
//         withProperties: true,
//       );

//       final userId = FirebaseAuth.instance.currentUser!.uid;
//       final userContactsRef = FirebaseFirestore.instance
//           .collection("users")
//           .doc(userId)
//           .collection("contacts");

//       WriteBatch batch = FirebaseFirestore.instance.batch();

//       for (var contact in contacts) {
//         if (contact.phones.isNotEmpty) {
//           final phone = contact.phones.first.number;
//           final docRef = userContactsRef.doc(phone);

//           batch.set(docRef, {
//             "name": contact.displayName,
//             "phone": phone,
//             "image": null,
//           });
//         }
//       }

//       await batch.commit();
//     } else {
//       _handleInvalidPermissions(permissionStatus);
//     }
//   }

//   Future<PermissionStatus> _getContactPermission() async {
//     PermissionStatus permission = await Permission.contacts.status;
//     if (permission != PermissionStatus.granted &&
//         permission != PermissionStatus.permanentlyDenied) {
//       return await Permission.contacts.request();
//     } else {
//       return permission;
//     }
//   }

//   void _handleInvalidPermissions(PermissionStatus permissionStatus) {
//     if (permissionStatus == PermissionStatus.denied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Access to contact data denied')),
//       );
//     } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Contact data not available on device')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     final userId = FirebaseAuth.instance.currentUser!.uid;

//     return Scaffold(
//       backgroundColor: const Color(0xff292929),
//       body: Column(
//         children: [
//           /// 🔹 Top Bar
//           _buildTopBar(size),

//           SizedBox(height: size.height * .06),

//           /// 🔹 Add Friend Button
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: SizedBox(
//               height: size.height * .06,
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xffECF9FF),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => Addcontact()),
//                   );
//                 },
//                 icon: const Icon(Icons.add, color: Color(0xff135CAF), size: 30),
//                 label: Text(
//                   "Add Friend ",
//                   style: Apptexts.subtitlestyle.copyWith(
//                     color: const Color(0xff135CAF),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           SizedBox(height: size.height * .04),
//           Expanded(
//             child: StreamBuilder(
//               stream:
//                   FirebaseFirestore.instance
//                       .collection("users")
//                       .doc(userId)
//                       .collection("contacts")
//                       .orderBy("name")
//                       .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 var contacts = snapshot.data!.docs;

//                 /// ✅ Filter contacts if searching
//                 if (searchQuery.isNotEmpty) {
//                   contacts =
//                       contacts.where((doc) {
//                         final data = doc.data();
//                         final name =
//                             (data["name"] ?? "").toString().toLowerCase();
//                         final phone =
//                             (data["phone"] ?? "").toString().toLowerCase();
//                         return name.contains(searchQuery.toLowerCase()) ||
//                             phone.contains(searchQuery.toLowerCase());
//                       }).toList();
//                 }

//                 if (contacts.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       "No contacts found",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.only(top: 0),
//                   shrinkWrap: true,
//                   itemCount: contacts.length,
//                   itemBuilder: (context, index) {
//                     final data = contacts[index].data();
//                     final name = data["name"] ?? "";
//                     final phone = data["phone"] ?? "";

//                     // ✅ Show first letter only if name exists
//                     final String? firstLetter =
//                         name.isNotEmpty ? name[0].toUpperCase() : null;

//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: const Color(0xff135CAF),
//                         child:
//                             firstLetter != null
//                                 ? Text(
//                                   firstLetter,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 )
//                                 : const Icon(Icons.person, color: Colors.white),
//                       ),
//                       title: Text(
//                         name.isNotEmpty ? name : phone, // show phone if no name
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Text(
//                         phone,
//                         style: const TextStyle(color: Color(0xff9A9BB1)),
//                       ),
//                       trailing: FutureBuilder(
//                         future:
//                             FirebaseFirestore.instance
//                                 .collection("users")
//                                 .where(
//                                   "phone",
//                                   isEqualTo: phone,
//                                 ) // check phone in users collection
//                                 .get(),
//                         builder: (context, snapshot) {
//                           if (!snapshot.hasData) {
//                             return const SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             );
//                           }

//                           final docs = snapshot.data!.docs;
//                           final isRegistered = docs.isNotEmpty;

//                           if (isRegistered) {
//                             final userDoc = docs.first;
//                             final chatUserId =
//                                 userDoc.id; // user’s uid in Firestore

//                             return IconButton(
//                               icon: const Icon(Icons.chat, color: Colors.green),
//                               onPressed: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder:
//                                         (_) => Chatscreen(
//                                           name: name,
//                                           image: "assets/images/default.png",
//                                           receiverId:
//                                               chatUserId,
//                                           phone: phone,
//                                         ),
//                                   ),
//                                 );
//                               },
//                             );
//                           } else {
//                             return TextButton(
//                               onPressed: () {

//                               },
//                               child: const Text(
//                                 "Invite",
//                                 style: TextStyle(color: Colors.blue),
//                               ),
//                             );
//                           }
//                         },
//                       ),

//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 🔹 Top Bar Widgets
//   Widget _buildTopBar(Size size) {
//     return Container(
//       width: double.infinity,
//       height: size.height * .14,
//       decoration: BoxDecoration(
//         color: const Color(0xff135CAF),
//         borderRadius: BorderRadius.only(
//           bottomRight: Radius.circular(size.width * 0.1),
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.only(top: 40, right: 20),
//         child: isSearching ? _buildSearchBar() : _buildHeader(size),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.only(left: 20, right: 10),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               cursorColor: const Color(0xff135CAF),
//               decoration: InputDecoration(
//                 hintText: 'Search...',
//                 fillColor: Colors.white,
//                 filled: true,
//                 hintStyle: const TextStyle(color: Color(0xff9A9BB1)),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//               style: Apptexts.bodystyle.copyWith(color: Colors.black),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value;
//                 });
//               },
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
//             onPressed: () {
//               setState(() {
//                 isSearching = false;
//                 searchQuery = "";
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(Size size) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         InkWell(
//           onTap: () => Navigator.pop(context),
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 10),
//             height: size.height * .07,
//             width: size.width * .13,
//             decoration: const BoxDecoration(
//               color: Color(0xff2a6cb7),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.arrow_back, color: Colors.white),
//           ),
//         ),
//         Text(
//           "Add Friends",
//           style: Apptexts.titlestyle.copyWith(color: Colors.white),
//         ),
//         IconButton(
//           icon: const Icon(Icons.search, color: Colors.white, size: 30),
//           onPressed: () {
//             setState(() {
//               isSearching = true;
//             });
//           },
//         ),
//       ],
//     );
//   }
// }

import 'package:chat_app/constants/text.dart';
import 'package:chat_app/homepage.dart/addcontact.dart';
import 'package:chat_app/homepage.dart/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

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
                            print(
                              "Error checking user registration: ${snapshot.error}",
                            );
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
                            return TextButton(
                              onPressed: () {
                                // Implement invite functionality
                                _inviteContact(displayPhone);
                              },
                              child: const Text(
                                "Invite",
                                style: TextStyle(color: Colors.blue),
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

  void _inviteContact(String phone) {
    print("Inviting $phone to join the app");
    // You can implement SMS/WhatsApp invite functionality here
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
