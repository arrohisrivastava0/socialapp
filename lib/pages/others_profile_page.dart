import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/pages/user_profile_page.dart';

import '../components/my_button.dart';
import '../components/wall_post_tile.dart';

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
  String name="--";
  String bio="--";
  int connectionCount=0;
  StreamSubscription? connectionListener;

  @override
  void initState() {
    super.initState();

    // Get the current user's ID
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    fetchUserData();
    // Check the connection status
    _checkConnectionStatus();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(widget.userId)
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

  void startListeningToConnectionCount() {
    connectionListener = FirebaseFirestore.instance
        .collection("Connections")
        .doc(widget.userId)
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

  void _toggleConnectionStatus() async {
    final connectionDocRef = FirebaseFirestore.instance
        .collection("Connections")
        .doc(currentUserId);

    final otherConnectionDocRef= FirebaseFirestore.instance
        .collection("Connections")
        .doc(widget.userId);

    if (isConnection) {
      // Remove the connection
      await connectionDocRef.update({
        'to': FieldValue.arrayRemove([widget.userId])
      });
      await otherConnectionDocRef.update({
        'to': FieldValue.arrayRemove([currentUserId])
      });
      setState(() {
        isConnection = false;
      });
    } else {
      // Add the connection
      await connectionDocRef.set({
        'to': FieldValue.arrayUnion([widget.userId])
      }, SetOptions(merge: true));
      await otherConnectionDocRef.set({
        'to': FieldValue.arrayUnion([currentUserId])
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

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("Users").doc(widget.userId).snapshots(),
        builder: (context, snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          else if(snapshot.hasData){
            Map<String, dynamic>? user=snapshot.data!.data();
            userName=user!['username'];
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
                  Text("$connectionCount connections"),
                  const SizedBox(height: 30),
                  MyButton(
                    onTap: _toggleConnectionStatus,
                    btnText: isConnection ? "Connected" : "Connect",
                  ),
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
                            timestamp: post['timestamp']?? 'No timestamp',
                            username: post['username'] ?? 'Unknown user',
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

      // body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      //   future: FirebaseFirestore.instance.collection("Users").doc(widget.userId).get(),
      //   builder: (context, snapshot){
      //     if(snapshot.connectionState==ConnectionState.waiting){
      //       return const Center(
      //         child: CircularProgressIndicator(),
      //       );
      //     }
      //     else if(snapshot.hasData){
      //       final user = snapshot.data!.data();
      //       if (user == null) {
      //         return const Center(child: Text("User not found"));
      //       }
      //
      //       return Column(
      //         children: [
      //           const SizedBox(height: 30),
      //           Text(user['name'] ?? "No Name"),
      //           Text(user['bio'] ?? "No Bio"),
      //           const SizedBox(height: 30),
      //           MyButton(
      //             onTap: _toggleConnectionStatus,
      //             btnText: isConnection ? "Connected" : "Connect",
      //           ),
      //         ],
      //       );
      //
      //     }
      //
      //     else{
      //       return const Center(child: Text("Error Fetching Data"));
      //     }
      //   },
      // ),

    );
  }
}
