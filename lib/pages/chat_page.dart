import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('Chat', style: TextStyle(color: Theme.of(context).colorScheme.surface),),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}
