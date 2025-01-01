import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/wall_post_tile.dart';

class SeparatePostPage extends StatefulWidget {
  final String postId;
  const SeparatePostPage({super.key, required this.postId});

  @override
  State<SeparatePostPage> createState() => _SeparatePostPageState();
}

class _SeparatePostPageState extends State<SeparatePostPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post"),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                    .collection('Posts')
                    .doc(widget.postId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("Error loading posts."));
              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("You have no life"));
              }


              final posts = snapshot.data!.data()!;
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return WallPostTile(
                    postId: post['postId'] ?? 'Unknown Post ID',
                    content: post['content'] ?? 'No content available',
                    username: post['username'] ?? 'Unknown user',
                    timestamp: post['timestamp']?? 'No timestamp',
                    userId: post['userId'] ?? 'Unknown User ID',
                  );
                },
              );
            },
          ),

          const Divider(),

          const Text(
            "Comments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),


        ],
      ),

    );
  }
}
