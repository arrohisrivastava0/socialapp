import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/components/my_button.dart';

class UserProfilePage extends StatefulWidget {
  UserProfilePage({super.key});


  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? currentUser= FirebaseAuth.instance.currentUser;
  String userName = "Loading...";

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser!.uid)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic>? user = snapshot.data();
        if (user != null && mounted) {
          setState(() {
            userName = user['username'] ?? "Unknown User";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userName = "User not found";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = "Error loading user";
        });
      }
    }
  }

  // Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc() async{
  //   return await FirebaseFirestore.instance.collection("Users").doc(currentUser!.uid).get();
  // }

  void logout()async{
    FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch user data on widget load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(userName, style: TextStyle(color: Theme.of(context).colorScheme.surface),),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout), color: Theme.of(context).colorScheme.surface,)
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection("Users").doc(currentUser!.uid).get(),
        builder: (context, snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          else if(snapshot.hasData){
            Map<String, dynamic>? user=snapshot.data!.data();
            userName=user!['username'];
            return Column(
              children: [
                Text(user!['email']),
                Text(user!['username']),
                MyButton(onTap: (){}, btnText: "Complete your account")
              ],
            );
          }

          else{
            return MyButton(onTap: (){}, btnText: "Complete your account");
          }
        },
      ),

    );
  }
}
