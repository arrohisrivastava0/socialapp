import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:show_hide_password/show_hide_password.dart';

class MyTextfield extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;
  final maxLines;
  const MyTextfield({super.key, this.controller, required this.hintText, required this.obscureText, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        maxLines: maxLines,
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)
            ),
          focusedBorder: OutlineInputBorder( // Ensure same border when focused
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.inversePrimary, width: 2),
          ),
            hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary)
        ),
      ),
    );
  }
}
