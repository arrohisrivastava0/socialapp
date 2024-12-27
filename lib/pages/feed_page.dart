import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:socialapp/components/wall_post_tile.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final TextEditingController feedTextController= TextEditingController();
  // List<String> userPosts = [];
  // List<String> connections=[];
  // late String currentUserId;

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
                  await postNewFeed(feedTextController.text);
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

  Stream<List<Map<String, dynamic>>> fetchFeedPosts() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Create a stream for user connections
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .snapshots()
        .asyncExpand((userDoc) {
      final connections = List<String>.from(userDoc.data()?['connections'] ?? []);
      connections.add(currentUserId); // Include current user's posts in the feed

      // Fetch posts based on connections
      return FirebaseFirestore.instance
          .collection('Posts')
          .where('userId', whereIn: connections)
          // .orderBy('timestamp', descending: true)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs.map((doc) => doc.data()).toList();
      });
    });
  }

  Future<void> postNewFeed(String content) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('Posts').add({
      'userId': currentUserId,
      'content': content,
      'timestamp': Timestamp.now(),
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshFeed() async {
    setState(() {});
    return await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:Text('W  A  L  L', style: TextStyle(color: Theme.of(context).colorScheme.surface),),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: LiquidPullToRefresh(
        animSpeedFactor: 4,
        color: Theme.of(context).colorScheme.inversePrimary,
        height: 100,
        onRefresh: _refreshFeed,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: fetchFeedPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Error loading posts."));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("You have no life"));
            }
        
            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return WallPostTile(
                  // title: Text(post['content']),
                  // subtitle: Text(post['userId']),
                  // trailing: Text((post['timestamp'] as Timestamp).toDate().toString()),
                  content: post['content'],
                  userId: post['userId'],
                  timestamp: post['timestamp']
                );
              },
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 20,
        onPressed: showPostDialog,
        child: const Icon(Icons.edit), // Pencil icon
      ),

    );
  }

}