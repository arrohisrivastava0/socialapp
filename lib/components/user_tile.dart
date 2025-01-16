import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final uid;
  final Function ()? onTap;
  const UserTile({super.key, required this.uid, this.onTap});

  Future<String> getUserName() async{
    final tokenDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get();
    return tokenDoc.data()?['username'];
  }

  Future<String> getName() async{
    final tokenDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get();
    return tokenDoc.data()?['name'];
  }

  @override
  Widget build(BuildContext context) {
    final username=getUserName();
    final name=getName();
    return ListTile(
      title: Text('$username'), // Replace with username
      subtitle: Text('$name'),
      onTap: onTap
    );
  }
}
