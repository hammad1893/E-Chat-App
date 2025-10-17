
import 'package:chat_app/model/authmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Authstate extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isloading = false;
  bool get isloading => _isloading;

  AuthModel? _usermodel;
  AuthModel? get usermodel => _usermodel;

  void setLoading(bool value) {
    _isloading = value;
    notifyListeners();
  }

  // ✅ Signup
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
      // FIX: Add null check for currentUser
      if (_auth.currentUser == null) {
        print("❌ No user is currently signed in");
        return;
      }

      String uid = _auth.currentUser!.uid;
      DocumentSnapshot snapshot =
          await _firestore.collection("users").doc(uid).get();

      // FIX: Check if document exists and has data
      if (snapshot.exists && snapshot.data() != null) {
        _usermodel = AuthModel.fromJson(
          snapshot.data() as Map<String, dynamic>,
        );
        notifyListeners();
      } else {
        print("❌ User document not found in Firestore");
        _usermodel = null;
      }
    } catch (e) {
      print("❌ Load User Error: $e");
      // Don't throw here, just log the error
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
      // FIX: Better null checking and user ID retrieval
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user is currently signed in");
      }

      String uid = currentUser.uid;

      // Create update data
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toString(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phoneNumber'] = phone;
      if (imageUrl != null) updateData['profilePicture'] = imageUrl;
      if (gender != null) updateData['gender'] = gender;
      if (dob != null) updateData['dob'] = dob;

      // Update Firestore
      await _firestore.collection("users").doc(uid).update(updateData);

      // Update local model
      if (_usermodel != null) {
        _usermodel = _usermodel!.copyWith(
          name: name ?? _usermodel!.name,
          phoneNumber: phone ?? _usermodel!.phoneNumber,
          profilePicture: imageUrl ?? _usermodel!.profilePicture,
          gender: gender ?? _usermodel!.gender,
          dob: dob ?? _usermodel!.dob,
          updatedAt: DateTime.now().toString(),
        );
      } else {
        // If local model is null, reload it
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

  // ✅ Preload all users for current chats


  Future<void> logout() async {
    await _auth.signOut();
    _usermodel = null;
    notifyListeners();
  }
}

  // ✅ Google Sign-In
  // Future<void> signInWithGoogle(BuildContext context) async {
  //   try {
  //     setLoading(true);

  //     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //     if (googleUser == null) {
  //       SnackbarMessage.failedsnack("Google Sign-In cancelled", context);
  //       setLoading(false);
  //       return;
  //     }

  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;

  //     final OAuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     final UserCredential userCredential = await _auth.signInWithCredential(
  //       credential,
  //     );

  //     final User? user = userCredential.user;

  //     if (user != null) {
  //       final DocumentSnapshot doc =
  //           await _firestore.collection("users").doc(user.uid).get();

  //       if (!doc.exists) {
  //         // New user → go to UserInfoScreen
  //         authmodel newUser = authmodel(
  //           id: user.uid,
  //           name: user.displayName ?? "No Name",
  //           email: user.email ?? "No Email",
  //           profilePicture: user.photoURL ?? "",
  //           timestamp: DateTime.now().toIso8601String(),
  //           updatedAt: DateTime.now().toIso8601String(),
  //         );

  //         await _firestore
  //             .collection("users")
  //             .doc(user.uid)
  //             .set(newUser.toJson());

  //         _usermodel = newUser;

  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(builder: (context) => Userinfoscreen()),
  //             (route) => false,
  //           );
  //         });
  //       } else {
  //         // Existing user → go to Home
  //         _usermodel = authmodel.fromJson(doc.data() as Map<String, dynamic>);

  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(builder: (context) => CustomBottomNavBar()),
  //             (route) => false,
  //           );
  //         });
  //       }

  //       SnackbarMessage.successsnack("Google Sign-In successful", context);
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     print("❌ FirebaseAuthException: ${e.code}");
  //     SnackbarMessage.failedsnack("Firebase Auth Error: ${e.message}", context);
  //   } catch (e) {
  //     print("❌ Google Sign-In Error: $e");
  //     SnackbarMessage.failedsnack("Google Sign-In failed: $e", context);
  //   } finally {
  //     setLoading(false);
  //   }
  // }
