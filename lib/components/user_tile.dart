import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String uid;
  final String? name;
  final VoidCallback? onTap;

  const UserTile({
    Key? key,
    required this.uid,
    this.name,
    this.onTap,
  }) : super(key: key);

  Future<String> getUserName() async {
    final tokenDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    return tokenDoc.data()?['username'] ?? 'Unknown User';
  }

  Future<String> getName() async {
    final tokenDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    return tokenDoc.data()?['name'] ?? 'No Name';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, usernameSnapshot) {
        if (usernameSnapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Loading...'),
            subtitle: Text('Loading...'),
          );
        } else if (usernameSnapshot.hasError) {
          return const ListTile(
            title: Text('Error'),
            subtitle: Text('Could not load user'),
          );
        } else {
          final username = usernameSnapshot.data ?? 'Unknown User';

          // Check if the name is provided, else fetch it asynchronously
          return FutureBuilder<String>(
            future: name == null ? getName() : Future.value(name),
            builder: (context, nameSnapshot) {
              if (nameSnapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  title: Text('Loading...'),
                  subtitle: Text('Loading...'),
                );
              } else if (nameSnapshot.hasError) {
                return ListTile(
                  title: Text(username),
                  subtitle: const Text('Error loading name'),
                  onTap: onTap,
                );
              } else {
                final nm = nameSnapshot.data ?? 'No Name';

                return ListTile(
                  title: Text(username),
                  subtitle: Text(nm),
                  onTap: onTap,
                );
              }
            },
          );
        }
      },
    );
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class UserTile extends StatelessWidget {
//   final uid;
//   final String? name;
//   final Function ()? onTap;
//   const UserTile({super.key, required this.uid, this.onTap, this.name});
//
//   Future<String> getUserName() async{
//     final tokenDoc = await FirebaseFirestore.instance
//         .collection('Users')
//         .doc(uid)
//         .get();
//     return tokenDoc.data()?['username'];
//   }
//
//   Future<String> getName() async{
//     final tokenDoc = await FirebaseFirestore.instance
//         .collection('Users')
//         .doc(uid)
//         .get();
//     return tokenDoc.data()?['name'];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     String username = '';
//     String nm = '';
//
//     // Fetch username
//     username = getUserName(); // Assuming getUserName() returns a string
//     if (name == null) {
//       // If name is null, fetch it
//       nm = getName(); // Assuming getName() also returns a string
//     } else {
//       nm = name!;
//     }
//
//     return ListTile(
//       title: Text(username), // Display username
//       subtitle: Text(nm), // Display the appropriate name
//       onTap: onTap,
//     );
//   }
//
//
// // @override
//   // Widget build(BuildContext context) {
//   //
//   //
//   //
//   //
//   //   // final username=getUserName();
//   //   // if(name==null){
//   //   //   final nm=getName();
//   //   // }
//   //   // else final nm=name;
//   //   // return ListTile(
//   //   //   title: Text('$username'), // Replace with username
//   //   //   subtitle: Text('$nm'),
//   //   //   onTap: onTap
//   //   // );
//   // }
// }
