import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart' as ts;
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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
  static void success(BuildContext context, String message) {
    _showCustomSnackbar(
      context,
      message: message,
      bgColor: Colors.green.shade600,
      icon: Icons.check_rounded,
      iconColor: Colors.green.shade100,
      position: ts.SnackBarPosition.top,
    );
  }

  static void info(BuildContext context, String message) {
    _showCustomSnackbar(
      context,
      message: message,
      bgColor: Colors.blue.shade600,
      icon: Icons.info_rounded,
      iconColor: Colors.blue.shade100,
      position: ts.SnackBarPosition.top,
    );
  }

  static void error(BuildContext context, String message) {
    _showCustomSnackbar(
      context,
      message: message,
      bgColor: Colors.red.shade600,
      icon: Icons.error_rounded,
      iconColor: Colors.red.shade100,
      position: ts.SnackBarPosition.bottom,
    );
  }

  static void _showCustomSnackbar(
    BuildContext context, {
    required String message,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required ts.SnackBarPosition position,
  }) {
    showTopSnackBar(
      Overlay.of(context),
      Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Modern Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.3), Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      snackBarPosition: position,
      displayDuration: const Duration(milliseconds: 1500),
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
