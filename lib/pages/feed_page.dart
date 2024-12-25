import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final TextEditingController feedTextController= TextEditingController();
  List<String> userPosts = [];

  // Function to show the popup dialog
  void showPostDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Write your thoughts'),
          content: TextField(
            controller: feedTextController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'What\'s on your mind?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                feedTextController.clear();
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Discard', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
            ),
            ElevatedButton(
              onPressed: () async {
                if (feedTextController.text.isNotEmpty) {
                  await postFeed(feedTextController.text);
                  feedTextController.clear();
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: const Text('Post'),
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(
                Theme.of(context).colorScheme.inversePrimary,
              ),),
            ),
          ],
        );
      },
    );
  }

  Future<void> postFeed(String post) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final connectionDocRef = FirebaseFirestore.instance.collection("UserPosts").doc(currentUserId);
      final allConnectionDocRef = FirebaseFirestore.instance.collection("UserPosts").doc("AllPosts");
      // Add a post with a timestamp directly to the document
      await connectionDocRef.set({
        'posts': FieldValue.arrayUnion([
          {
            'post': post,
            'timestamp': Timestamp.now(), // Use Timestamp.now() for the timestamp
          }
        ]),
      }, SetOptions(merge: true)); // Merge ensures the document is created if it doesn't exist

      await allConnectionDocRef.set({
        currentUserId : FieldValue.arrayUnion([
          {
            'post': post,
            'timestamp': Timestamp.now(), // Use Timestamp.now() for the timestamp
          }
        ]),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error posting feed: $e");
    }
  }


  // Stream<List<Map<String, dynamic>>> getAllConnectedUserPosts() async* {
  //   final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  //
  //   // Fetch connections
  //   final connectionsSnapshot = await FirebaseFirestore.instance
  //       .collection("UserConnections")
  //       .doc(currentUserId)
  //       .get();
  //   final connections = List<String>.from(connectionsSnapshot.data()?['connections'] ?? []);
  //
  //   // Create a list of streams for each user's posts
  //   final streams = connections.map((userId) {
  //     return FirebaseFirestore.instance
  //         .collection("UserPosts")
  //         .doc(userId)
  //         .snapshots()
  //         .map((snapshot) {
  //       if (snapshot.exists) {
  //         final List<dynamic> rawPosts = snapshot.data()?['posts'] ?? [];
  //         return rawPosts.map((post) => post as Map<String, dynamic>).toList();
  //       }
  //       return [];
  //     });
  //   }).toList();
  //
  //   // Combine streams and yield a single stream of posts
  //   final streamGroup = StreamGroup<List<Map<String, dynamic>>>();
  //
  //   // Add each stream to the group
  //   for (var stream in streams) {
  //     streamGroup.add(stream);
  //   }
  //
  //   // Listen to all streams and emit the combined data
  //   await for (var postsList in streamGroup.stream) {
  //     List<Map<String, dynamic>> allPosts = [];
  //
  //     // Combine all posts and sort by timestamp
  //     for (var posts in postsList) {
  //       allPosts.addAll(posts);
  //     }
  //
  //     allPosts.sort((a, b) {
  //       final timeA = (a['timestamp'] as Timestamp).toDate();
  //       final timeB = (b['timestamp'] as Timestamp).toDate();
  //       return timeB.compareTo(timeA); // Newest to oldest
  //     });
  //
  //     // Yield the sorted posts
  //     yield allPosts;
  //   }
  // }

  // Stream<List<Map<String, dynamic>>> getAllConnectedUserPosts() async* {
  //   final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  //
  //   // Fetch connections
  //   final connectionsSnapshot = await FirebaseFirestore.instance
  //       .collection("UserConnections")
  //       .doc(currentUserId)
  //       .get();
  //   final connections = List<String>.from(connectionsSnapshot.data()?['connections'] ?? []);
  //
  //   // Listen to posts of connected users
  //   final streams = connections.map((userId) {
  //     return FirebaseFirestore.instance
  //         .collection("UserPosts")
  //         .doc(userId)
  //         .snapshots()
  //         .map((snapshot) {
  //       if (snapshot.exists) {
  //         final List<dynamic> rawPosts = snapshot.data()?['posts'] ?? [];
  //         return rawPosts.map((post) => post as Map<String, dynamic>).toList();
  //       }
  //       return [];
  //     });
  //   });
  //
  //   // Combine streams and sort by timestamp
  //   yield* Stream<List<Map<String, dynamic>>>.multi((controller) {
  //     final subscriptions = streams.map((stream) {
  //       return stream.listen((userPosts) {
  //         final allPosts = [...userPosts].toList();
  //         allPosts.sort((a, b) {
  //           final timeA = (a['timestamp'] as Timestamp).toDate();
  //           final timeB = (b['timestamp'] as Timestamp).toDate();
  //           return timeB.compareTo(timeA); // Newest to oldest
  //         });
  //         controller.add(allPosts);
  //       });
  //     });
  //     return () => subscriptions.forEach((subscription) => subscription.cancel());
  //   });
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:Text('W  A  L  L', style: TextStyle(color: Theme.of(context).colorScheme.surface),),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // body: StreamBuilder<DocumentSnapshot>(
      //   stream: FirebaseFirestore.instance
      //       .collection("UserPosts")
      //       .doc("AllPosts")
      //       .snapshots(),
      //   builder: (context, snapshot) {
      //     if (snapshot.hasError) {
      //       return Center(child: Text('Error loading posts.'));
      //     }
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator());
      //     }
      //
      //     final data = snapshot.data?.data() as Map<String, dynamic>?;
      //     final userPosts = snapshot.data?['posts'] as List<Map<String, dynamic>>?;
      //     if (userPosts == null || userPosts.isEmpty) {
      //       return Center(
      //         child: Text(
      //           'You have no social life.',
      //           style: Theme.of(context).textTheme.bodyLarge,
      //         ),
      //       );
      //     }
      //   },
      //
      // ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 20,
        onPressed: showPostDialog,
        child: const Icon(Icons.edit), // Pencil icon
      ),

    );
  }

// Stream<List<Map<String, dynamic>>> getUserPosts() async* {
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid;
//   final connectionDocRef = FirebaseFirestore.instance.collection("UserPosts").doc(currentUserId);
//
//   connectionDocRef.snapshots().listen((snapshot) {
//     if (snapshot.exists) {
//       final List<dynamic> rawPosts = snapshot.data()?['posts'] ?? [];
//       final posts = rawPosts.map((post) => post as Map<String, dynamic>).toList();
//       yield posts;
//     } else {
//       yield [];
//     }
//   });
// }
}
