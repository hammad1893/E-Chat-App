import 'package:chat_app/bottomnavigation.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/mainscreen/userinfoscreen.dart';
import 'package:chat_app/model/authmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authstate extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool _isloading = false;
  bool get isloading => _isloading;

  AuthModel? _usermodel;
  AuthModel? get usermodel => _usermodel;

  void setLoading(bool value) {
    _isloading = value;
    notifyListeners();
  }

  //  Signup
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isloading = true;
      notifyListeners();

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      AuthModel usermodel = AuthModel(
        id: uid,
        name: name,
        email: email,
        profilePicture: null,
        phoneNumber: null,
        timestamp: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection("users").doc(uid).set(usermodel.toJson());

      _usermodel = usermodel;
    } catch (e) {
      print("❌ Signup Error: $e");
      throw Exception(e.toString());
    } finally {
      _isloading = false;
      notifyListeners();
    }
  }

  Future<void> loaduserdate() async {
    try {
      if (_auth.currentUser == null) {
        print("❌ No user is currently signed in");
        return;
      }

      String uid = _auth.currentUser!.uid;
      DocumentSnapshot snapshot =
          await _firestore.collection("users").doc(uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        print("Firestore user data: $data"); 
        _usermodel = AuthModel.fromJson(data);
        notifyListeners();
      } else {
        print("❌ User document not found in Firestore");
        _usermodel = null;
      }
    } catch (e) {
      print("❌ Load User Error: $e");
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? imageUrl,
    String? gender,
    String? dob,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user is currently signed in");
      }

      String uid = currentUser.uid;

      final updateData = <String, dynamic>{'updatedAt': DateTime.now()};

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phoneNumber'] = phone;
      if (imageUrl != null) updateData['profilePicture'] = imageUrl;
      if (gender != null) updateData['gender'] = gender;
      if (dob != null) updateData['dob'] = dob;

      await _firestore.collection("users").doc(uid).update(updateData);

      if (_usermodel != null) {
        _usermodel = _usermodel!.copyWith(
          name: name ?? _usermodel!.name,
          phoneNumber: phone ?? _usermodel!.phoneNumber,
          profilePicture: imageUrl ?? _usermodel!.profilePicture,
          gender: gender ?? _usermodel!.gender,
          dob: dob ?? _usermodel!.dob,
          updatedAt: DateTime.now(),
        );
      } else {
        await loaduserdate();
      }

      notifyListeners();
    } catch (e) {
      print("❌ Update Profile Error: $e");
      throw Exception("Update failed: $e");
    }
  }

  // ✅ Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _isloading = true;
      notifyListeners();

      // ignore: unused_local_variable
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await loaduserdate();

      return null; // ✅ success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No user found with this email";
      } else if (e.code == 'wrong-password') {
        return "Incorrect password, try again";
      } else {
        return "Invalid email or password";
      }
    } catch (e) {
      return "An unexpected error occurred";
    } finally {
      _isloading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign-In cancelled'),
            backgroundColor: Colors.red,
          ),
        );
        print('⚠️ Sign-In cancelled');
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // ✅ Check if user exists in Firestore
        final DocumentSnapshot doc =
            await _firestore.collection("users").doc(user.uid).get();

        if (!doc.exists) {
          await _saveUserToFirestore(user);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Userinfoscreen()),
              (route) => false,
            );
          });
        } else {
          _usermodel = AuthModel.fromJson(doc.data() as Map<String, dynamic>);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => CustomBottomNavBar()),
              (route) => false,
            );
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign-In successful'),
            backgroundColor: Colors.green,
          ),
        );
        print('✅ Sign-In successful');
        print('User ID: ${user.uid}');
        print('User email: ${user.email}');
        print('User display name: ${user.displayName}');
        print('User photo URL: ${user.photoURL}');
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code}");
      SnackbarMessage.failedsnack("Firebase Auth Error: ${e.message}", context);
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      SnackbarMessage.failedsnack("Google Sign-In failed: $e", context);
    } finally {
      setLoading(false);
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    final DocumentSnapshot doc =
        await _firestore.collection("users").doc(user.uid).get();

    if (!doc.exists) {
      // New user → go to UserInfoScreen
      final newUser = AuthModel(
        id: user.uid,
        name: user.displayName ?? "No Name",
        email: user.email ?? "No Email",
        profilePicture: user.photoURL ?? "",
        timestamp: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection("users").doc(user.uid).set(newUser.toJson());

      _usermodel = newUser;
      print("✅ Firestore user created");
    } else {
      print("ℹ️ Firestore user already exists");
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _usermodel = null;
    notifyListeners();
  }
}
