import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    // Check the connection status
    _checkConnectionStatus();
  }

  void _checkConnectionStatus() async {

    // final currentUserId = FirebaseAuth.instance.currentUser!.uid; // Replace with the logged-in user's ID
    final connectionDocId = "${currentUserId}_${widget.userId}";

    final connectionDoc = await FirebaseFirestore.instance
        .collection("Connections")
        .doc(connectionDocId)
        .get();

    setState(() {
      isConnection = connectionDoc.exists;
    });
  }

  void _toggleConnectionStatus() async {
    final connectionDocRef = FirebaseFirestore.instance
        .collection("Connections")
        .doc(currentUserId);

    if (isConnection) {
      // Remove the connection
      await connectionDocRef.update({
        'to': FieldValue.arrayRemove([{
          widget.userId: FieldValue.serverTimestamp()  // Removes the map with the specific userId
        }])
      });
      setState(() {
        isConnection = false;
      });
    } else {

      await connectionDocRef.update({
        'to': FieldValue.arrayUnion([{
          widget.userId: FieldValue.serverTimestamp()  // Adds the userId with current timestamp
        }])
      });
      // Add the connection
      // await connectionDocRef.update({
      //   'to': FieldValue.arrayUnion([{
      //     'uid': widget.userId,
      //     'timestamp': FieldValue.serverTimestamp()
      //   }])
      // });
      setState(() {
        isConnection = true;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text(userName, style: TextStyle(color: Theme.of(context).colorScheme.surface),),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // actions: [
        //   IconButton(onPressed: logout, icon: const Icon(Icons.logout), color: Theme.of(context).colorScheme.surface,)
        // ],
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
            Map<String, dynamic>? user=snapshot.data!.data();

            userName=user!['username'];
            // nameTextController.text=name;
            // bioTextController.text=bio;
            return Column(
              children: [
                SizedBox(height: 30,),
                Text(user!['name']),
                Text(user!['bio']),

                SizedBox(height: 30,),
                MyButton(onTap: _toggleConnectionStatus, btnText: isConnection ? "Connected" : "Connect",)
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
}
