import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/components/my_button.dart';
import 'package:socialapp/components/my_obscure_textfield.dart';
import 'package:socialapp/components/my_textfield.dart';
import 'package:show_hide_password/show_hide_password.dart';

import '../helper/helper_dialogue.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailTextController = TextEditingController();

  final TextEditingController passTextController = TextEditingController();

  void userLogin() async {
    if (emailTextController.text.isEmpty ||
        passTextController.text.isEmpty) {
      if (mounted) {
        displayErrorMessage("All fields are required!", context);
      }
      return;
    }
    else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) =>
          const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailTextController.text,
              password: passTextController.text);
          Navigator.pop(context);
          displayErrorMessage("Successfully Logged In!", context);
        }
        on FirebaseAuthException catch (e) {
          Navigator.pop(context);
          displayErrorMessage('An unknown error occurred', context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //app logo
            Icon(
              Icons.local_pizza,
              size: 60,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            const SizedBox(height: 15),
            //app name
            const Text(
              "P  I  J  J  O",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 30),
            //email textfield
            MyTextfield(
                controller: emailTextController,
                hintText: 'Email',
                obscureText: false
            ),
            const SizedBox(height: 10),
            //password textfield
            MyObscureTextfield(
              controller: passTextController,
              hintText: 'Password',
            ),
            const SizedBox(height: 10),
            Text('Forgot Password?', style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),
            const SizedBox(height: 30),

            //sign in button
            MyButton(onTap: userLogin, btnText: 'Login'),

            const SizedBox(height: 10),
            //sign up

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Don\'t have an account?'),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text('Sign Up!', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

