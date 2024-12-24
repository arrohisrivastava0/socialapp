import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/pages/user_profile_page.dart';

import '../components/my_button.dart';

class OthersProfilePage extends StatefulWidget {
  final String userId;
  // final String username;
  const OthersProfilePage({super.key, required this.userId});

  @override
  State<OthersProfilePage> createState() => _OthersProfilePageState();
}

class _OthersProfilePageState extends State<OthersProfilePage> {
  bool isConnection= false;
  late String currentUserId;
  String userName= "Loading...";

  @override
  void initState() {
    super.initState();

    // Get the current user's ID
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _fetchUserData();
    // Check the connection status
    _checkConnectionStatus();
  }

  void _fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection("Users").doc(widget.userId).get();
    if (userDoc.exists) {
      setState(() {
        userName = userDoc.data()!['username'] ?? "Unknown User";
      });
    }
  }

  void _checkConnectionStatus() async {
    final connectionDoc = await FirebaseFirestore.instance
        .collection("Connections")
        .doc(currentUserId)
        .get();

    if (connectionDoc.exists) {
      final connections = List<String>.from(connectionDoc.data()?['to'] ?? []);
      setState(() {
        isConnection = connections.contains(widget.userId);
      });
    }
  }



  void _toggleConnectionStatus() async {
    final connectionDocRef = FirebaseFirestore.instance
        .collection("Connections")
        .doc(currentUserId);

    if (isConnection) {
      // Remove the connection
      await connectionDocRef.update({
        'to': FieldValue.arrayRemove([widget.userId])
      });
      setState(() {
        isConnection = false;
      });
    } else {
      // Add the connection
      await connectionDocRef.set({
        'to': FieldValue.arrayUnion([widget.userId])
      }, SetOptions(merge: true));
      setState(() {
        isConnection = true;
      });

    }
    await FirebaseFirestore.instance.collection("Users").doc(currentUserId).update({
      'connections': FieldValue.arrayUnion([widget.userId])
    });

  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(userName, style: TextStyle(color: Theme.of(context).colorScheme.surface),),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection("Users").doc(widget.userId).get(),
        builder: (context, snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          else if(snapshot.hasData){
            final user = snapshot.data!.data();
            if (user == null) {
              return const Center(child: Text("User not found"));
            }

            return Column(
              children: [
                const SizedBox(height: 30),
                Text(user['name'] ?? "No Name"),
                Text(user['bio'] ?? "No Bio"),
                const SizedBox(height: 30),
                MyButton(
                  onTap: _toggleConnectionStatus,
                  btnText: isConnection ? "Connected" : "Connect",
                ),
              ],
            );

          }

          else{
            return const Center(child: Text("Error Fetching Data"));
          }
        },
      ),

    );
  }
}
