import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:socialapp/components/my_button.dart';

import '../components/my_textfield.dart';
import '../components/wall_post_tile.dart';
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
  StreamSubscription? connectionListener;

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
            connectionCount=user['num_connections'];
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

  void startListeningToConnectionCount() {
    connectionListener = FirebaseFirestore.instance
        .collection("Connections")
        .doc(currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final connections = List<String>.from(snapshot.data()?['to'] ?? []);
        setState(() {
          connectionCount = connections.length;
        });
      } else {
        setState(() {
          connectionCount = 0;
        });
      }
    });
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

  Stream<List<Map<String, dynamic>>> fetchFeedPosts() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      // Fetch posts based on connections
      return FirebaseFirestore.instance
          .collection('Posts')
          .where('userId', isEqualTo: currentUserId)
      // .orderBy('timestamp', descending: true)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs.map((doc) => doc.data()).toList();
      });
  }

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch user data on widget load
    startListeningToConnectionCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(userName, style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout), color: Theme.of(context).colorScheme.inversePrimary,)
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("Users").doc(currentUser!.uid).snapshots(),
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
            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 30,),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                    radius: 50,
                    child: Text(user!['name'][0].toUpperCase(), style: TextStyle(fontSize: 30),),
                  ),
                  SizedBox(height: 10,),
                  Text(user!['name'], style: TextStyle(fontSize: 25),),
                  Text(user!['bio'], style: TextStyle(fontSize: 17),),
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
                  MyButton(onTap: showMenu, btnText: "Edit your profile"),
                  const SizedBox(height: 40),
                  Text("P O S T S", style: TextStyle(fontSize: 20),),
                  Divider(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    height: 6,
                    thickness: 1,
                    indent: 13,
                    endIndent: 13,
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: fetchFeedPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text("Error loading posts."));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("You have no opinions"));
                      }

                      final posts = snapshot.data!;
                      return Column(  // Use Column instead of ListView to list posts without scrolling
                        children: posts.map((post) {
                          return WallPostTile(
                            postId: post['postId'] ?? 'Unknown Post ID',
                            content: post['content'] ?? 'No content available',
                            username: post['username'] ?? 'Unknown user',
                            timestamp: post['timestamp']?? 'No timestamp',
                            userId: post['userId'] ?? 'Unknown User ID',
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],

              ),
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
      startListeningToConnectionCount();
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

  @override
  void dispose() {
    connectionListener?.cancel();
    nameTextController.dispose();
    bioTextController.dispose();
    super.dispose();
  }

}
