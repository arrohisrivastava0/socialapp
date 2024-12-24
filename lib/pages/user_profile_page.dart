import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:socialapp/components/my_button.dart';

import '../components/my_textfield.dart';
import '../helper/confirmation_dialogue.dart';
import '../helper/helper_dialogue.dart';
import 'connections_list_page.dart';

class UserProfilePage extends StatefulWidget {
  UserProfilePage({super.key});


  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController nameTextController= TextEditingController();
  final TextEditingController bioTextController= TextEditingController();
  User? currentUser= FirebaseAuth.instance.currentUser;
  String userName = "Loading...";
  String name="--";
  String bio="--";
  int connectionCount=0;

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
            name=user['name'];
            bio=user['bio'];
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

  Future<void> fetchConnectionCount() async {
    try {
      QuerySnapshot connectionsSnapshot = await FirebaseFirestore.instance
          .collection("Connections")
          .where("from", isEqualTo: currentUser!.uid)
          .get();

      setState(() {
        connectionCount = connectionsSnapshot.docs.length;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          connectionCount = 0; // Default to 0 in case of error
        });
      }
    }
  }


  void logout()async{
    final bool? confirmed = await showConfirmationDialog(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to Logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
    );
    if (confirmed == true){
      FirebaseAuth.instance.signOut();
    }
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
            nameTextController.text=name;
            bioTextController.text=bio;
            return Column(
              children: [
                SizedBox(height: 30,),
                Text(user!['name']),
                Text(user!['bio']),
                SizedBox(height: 30,),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConnectionsListPage( userId: currentUser!.uid,),
                    ),
                  ),
                  child: Text("$connectionCount connections"),
                ),
                const SizedBox(height: 30),
                MyButton(onTap: showMenu, btnText: "Complete your profile")
              ],
            );
          }

          else{
            return Text("Error Fetching Data");
          }
        },
      ),

    );
  }

  showMenu() {
    showBarModalBottomSheet(
      clipBehavior: Clip.none,
      expand: false,
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Fit content height
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 30),
                ClipOval(
                  child: GestureDetector(
                    onTap: () {}, // Image tapped
                    child: Image.asset(
                      'lib/assets/images/user.png',
                      fit: BoxFit.cover, // Fixes border issues
                      width: 110.0,
                      height: 110.0,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                MyTextfield(
                  hintText: "Name",
                  obscureText: false,
                  controller: nameTextController,
                ),
                const SizedBox(height: 15),
                MyTextfield(
                  hintText: "Bio",
                  obscureText: false,
                  controller: bioTextController,
                ),
                const SizedBox(height: 30),
                MyButton(onTap: saveDetails, btnText: "Save"),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void saveDetails() async{
    showDialog(context: context, builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ));
    try {
      User? currentUser= FirebaseAuth.instance.currentUser;
      if (nameTextController.text.isNotEmpty ||
          bioTextController.text.isNotEmpty){
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(currentUser!.uid)
            .update({
          'name': nameTextController.text,
          'bio': bioTextController.text
        });
      }
      setState(() {
        name = nameTextController.text;
        bio=bioTextController.text;// Update locally
      });
      await fetchUserData(); // Refresh the entire user data
      Navigator.pop(context);
      if(context.mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
    on FirebaseAuthException catch(e) {
      Navigator.pop(context);
      displayErrorMessage('An unknown error occurred', context);
    }
  }

}
