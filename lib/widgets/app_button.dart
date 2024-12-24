import 'package:flutter/material.dart';

class AppButton extends StatefulWidget {
  final Widget text;
  final Future<void> Function() onPressed;
  final ButtonStyle? style;

  const AppButton({required this.text, required this.onPressed, this.style, super.key});

  @override
  AppButtonState createState() => AppButtonState();
}

class AppButtonState extends State<AppButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: widget.style,
      onPressed: _isLoading
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });

              await widget.onPressed();

              if (context.mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : widget.text,
    );
  }
}
