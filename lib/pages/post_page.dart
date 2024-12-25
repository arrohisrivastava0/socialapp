import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/my_textfield.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController feedTextController= TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('Post', style: TextStyle(color: Theme.of(context).colorScheme.surface),),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: MyTextfield(
          controller: feedTextController,
          hintText: 'Say something...',
          obscureText: false
      ),
    );
  }
}
