import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';

class SnackbarMessage {
  static void successsnack(String message, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void failedsnack(String message, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class AppUtils {
  // Toast
  static void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
}

class LoadingIndicators {
  static Widget chatMessageShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(width: 120, height: 14, color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget chatListShimmer() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 25,
            ),
            title: Container(
              width: double.infinity,
              height: 16,
              color: Colors.grey[300],
            ),
            subtitle: Container(
              width: 100,
              height: 14,
              color: Colors.grey[300],
            ),
          ),
        );
      },
    );
  }

  static Widget circularProgress() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff2c2d3a),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff40C4FF)),
          strokeWidth: 3,
        ),
      ),
    );
  }

  static Widget messageBubbleShimmer(bool isMe) {
    return Shimmer.fromColors(
      baseColor: isMe ? Colors.blue[300]! : Colors.grey[300]!,
      highlightColor: isMe ? Colors.blue[100]! : Colors.grey[100]!,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[300] : Colors.grey[300],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
          ),
          width: 200,
          height: 60,
        ),
      ),
    );
  }
}
