import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/components/my_button.dart';
import 'package:socialapp/components/my_obscure_textfield.dart';
import 'package:socialapp/components/my_textfield.dart';
import 'package:show_hide_password/show_hide_password.dart';
import 'package:socialapp/helper/helper_dialogue.dart';

class SignupPage extends StatefulWidget {
  final void Function()? onTap;
  SignupPage({super.key, required this.onTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameTextController= TextEditingController();

  final TextEditingController emailTextController= TextEditingController();

  final TextEditingController passTextController= TextEditingController();

  final TextEditingController confirmPassTextController= TextEditingController();

  void userRegister() async{
    if(passTextController.text!=confirmPassTextController.text){
      displayErrorMessage("Passowords don't match!", context);
    }

    else if (usernameTextController.text.isEmpty ||
        emailTextController.text.isEmpty ||
        passTextController.text.isEmpty ||
        confirmPassTextController.text.isEmpty) {
      displayErrorMessage("All fields are required!", context);
      return;
    }
    else{
      showDialog(context: context, builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ));

      try {
        UserCredential userCredential=await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailTextController.text, password: passTextController.text);
        Navigator.pop(context);
        displayErrorMessage("Successfully Registered!", context);
        createUserDoc(userCredential);
        if(context.mounted) Navigator.pop(context);
      }
      on FirebaseAuthException catch(e) {
        Navigator.pop(context);
        displayErrorMessage('An unknown error occurred', context);
      }
    }

  }

  Future<void> createUserDoc(UserCredential? userCredential)async {
    if(userCredential!=null && userCredential.user!=null){
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.uid)
          .set({
        'email': userCredential.user!.email,
        'username': usernameTextController.text,
        'name': "--",
        'bio': "--",
        // 'num_connections':0
      });

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
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
              //username textfield
              MyTextfield(
                  controller: usernameTextController,
                  hintText: 'Create Username',
                  obscureText: false
              ),
              const SizedBox(height: 10),
              //email textfield
              MyTextfield(
                  controller: emailTextController,
                  hintText: 'Email ID',
                  obscureText: false
              ),
              const SizedBox(height: 10),
              //password textfield
              MyObscureTextfield(
                controller: passTextController,
                hintText: 'Create Password',
              ),
              const SizedBox(height: 10),
              //confirm password textfield
              MyObscureTextfield(
                controller: confirmPassTextController,
                hintText: 'Confirm Password',
              ),
        
              // Text('Forgot Password?', style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),
              const SizedBox(height: 30),
        
              //sign up button
              MyButton(onTap: userRegister, btnText: 'Register'),
        
              const SizedBox(height: 10),
        
              //sign in
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  const SizedBox(width: 5),
                  GestureDetector(
                    child: Text('Sign In!', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                    onTap: widget.onTap,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
