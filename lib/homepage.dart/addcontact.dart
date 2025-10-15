import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/widget/elevatedbutton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class Addcontact extends StatefulWidget {
  const Addcontact({super.key});

  @override
  State<Addcontact> createState() => _AddcontactState();
}

class _AddcontactState extends State<Addcontact> {
  TextEditingController firstnamecontroller = TextEditingController();
  TextEditingController lastnamecontroller = TextEditingController();
  String phoneNumber = "";
  String? duplicateError;

  String normalizePhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (phone.startsWith('0')) {
      phone = '+92' + phone.substring(1);
    }

    if (!phone.startsWith('+')) {
      phone = '+92' + phone;
    }

    return phone;
  }

  Future<void> checkDuplicate(String phone) async {
    final normalized = normalizePhoneNumber(phone);
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("contacts")
        .doc(normalized);

    final doc = await docRef.get();

    setState(() {
      duplicateError =
          doc.exists ? "This number is already in your contacts" : null;
    });
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
            margin: const EdgeInsets.only(left: 08),
            decoration: BoxDecoration(
              color: Color(0xff2a6cb7),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),

        title: Text(
          "Add Friend",
          style: Apptexts.titlestyle.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: size.height * .04),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: firstnamecontroller,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                label: Text(
                  "First Name",
                  style: Apptexts.bodystyle.copyWith(color: Color(0xffF0F0F3)),
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: lastnamecontroller,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                label: Text(
                  "Last Name",
                  style: Apptexts.bodystyle.copyWith(color: Color(0xffF0F0F3)),
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntlPhoneField(
                  decoration: InputDecoration(
                    hintText: "Enter Phone Number",
                    hintStyle: TextStyle(color: Color(0xffF0F0F3)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff9A9BB1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xff9A9BB1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xff9A9BB1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownTextStyle: const TextStyle(color: Colors.white),
                  initialCountryCode: 'PK',
                  onChanged: (phone) async {
                    phoneNumber = normalizePhoneNumber(phone.completeNumber);
                    await checkDuplicate(phoneNumber);
                  },
                ),
                if (duplicateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 5),
                    child: Text(
                      duplicateError!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: size.height * .04),
          CustomElevatedButton(
            text: "Add Friend",
            onPress: () async {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              final normalizedPhone = normalizePhoneNumber(phoneNumber);
              String firstName = firstnamecontroller.text.trim();
              String lastName = lastnamecontroller.text.trim();
              String fullName = "$firstName $lastName".trim();

              if (fullName.isEmpty || phoneNumber.isEmpty) {
                SnackbarMessage.failedsnack(
                  "Please enter both name and phone number",
                  context,
                );
                return;
              }

              final docRef = FirebaseFirestore.instance
                  .collection("users")
                  .doc(userId)
                  .collection("contacts")
                  .doc(normalizedPhone);

              await docRef.set({
                "name": fullName,
                "phone": normalizedPhone,
                "image": null,
              });
              print("Contact Added");
              print("fullName: $fullName, Phone: $phoneNumber");
              AppUtils.showToast("Contact Added Successfully");
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
