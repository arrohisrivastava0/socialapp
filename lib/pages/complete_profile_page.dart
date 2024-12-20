import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/my_textfield.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController nameTextController = TextEditingController();
  final TextEditingController bioTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .surface,
        body: Center(
            child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //username textfield
                      MyTextfield(
                          controller: nameTextController,
                          hintText: 'Create Username',
                          obscureText: false
                      ),
                      const SizedBox(height: 10),
                      //email textfield
                      MyTextfield(
                          controller: bioTextController,
                          hintText: 'Email ID',
                          obscureText: false
                      ),
                      Text('Max limit 500 characters', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
                    ]
                )
            )
        )
    );
  }
}
