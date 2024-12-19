import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:show_hide_password/show_hide_password.dart';

class MyObscureTextfield extends StatelessWidget {
  final controller;
  final String hintText;
  const MyObscureTextfield({super.key, this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 25.0),

    child: ShowHidePassword(
      hidePassword: true,
        passwordField: (hidePassword){
          return  TextField(
                controller: controller,
                obscureText: hidePassword,
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
              );
        },
      iconSize: 18,
      visibleOffIcon: Icons.visibility_off,
      visibleOnIcon: Icons.visibility,
    ),
    );
  }
}
