import 'package:chat_app/view/constants/text.dart';
import 'package:flutter/material.dart';

class ReactiveBorderTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool? obsecureText;
  final TextEditingController? controller;
  final VoidCallback? onSuffixTap; // Optional for things like visibility toggle

  const ReactiveBorderTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.onSuffixTap,
    this.obsecureText,
  });

  @override
  State<ReactiveBorderTextField> createState() =>
      _ReactiveBorderTextFieldState();
}

class _ReactiveBorderTextFieldState extends State<ReactiveBorderTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Color _borderColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      setState(() => _borderColor = Color(0xff40C4FF));
    } else if (!_focusNode.hasFocus) {
      setState(() => _borderColor = Colors.white);
    }
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty) {
      setState(() => _borderColor = Color(0xff40C4FF));
    } else if (_focusNode.hasFocus && _controller.text.isEmpty) {
      setState(() => _borderColor = Color(0xff40C4FF));
    } else {
      setState(() => _borderColor = Colors.white);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30),
      child: TextField(
        obscureText: widget.obsecureText ?? false,
        controller: _controller,
        focusNode: _focusNode,
        cursorColor: Colors.white,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: Apptexts.subtitlestyle.copyWith(color: Colors.white),
          label: Text(
            widget.label,
            style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
          ),
          prefixIcon:
              widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: Colors.white)
                  : null,
          suffixIcon:
              widget.suffixIcon != null
                  ? GestureDetector(
                    onTap: widget.onSuffixTap,
                    child: Icon(widget.suffixIcon, color: Colors.white),
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: _borderColor),
          ),
        ),
      ),
    );
  }
}
