import 'package:chat_app/constants/text.dart';
import 'package:flutter/material.dart';

class CustomElevatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPress;
  const CustomElevatedButton({super.key, required this.text, this.onPress});

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: widget.onPress,
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
                widget.text,
                style: Apptexts.titlestyle.copyWith(color: Color(0xff292929)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
