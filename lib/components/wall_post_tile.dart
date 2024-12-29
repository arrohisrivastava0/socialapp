import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WallPostTile extends StatefulWidget {
  final String postId;
  final String content;
  final String userId;
  final Timestamp timestamp;

  const WallPostTile({
    Key? key,
    required this.content,
    required this.userId,
    required this.timestamp,
    required this.postId,
  }) : super(key: key);

  @override
  State<WallPostTile> createState() => _WallPostTileState();
}

class _WallPostTileState extends State<WallPostTile> {
  bool isLiked = false;
  int likeCount = 0;

  Future<void> _checkIfLiked() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final postDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId) // Use the specific postId
        .get();

    if (postDoc.exists) {
      final likes = List<String>.from(postDoc.data()?['likes'] ?? []);
      setState(() {
        isLiked = likes.contains(currentUserId);
        likeCount = likes.length;
      });
    }
  }


  Future<void> likePost() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final postRef = FirebaseFirestore.instance.collection("Posts").doc(widget.postId);

    if (isLiked) {
      // Unlike the post
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      // Like the post
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });
    }

    // Refresh like state
    await _checkIfLiked();
  }



  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.onPrimary,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture and Username
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  child: Text(
                    widget.userId.isNotEmpty ? widget.userId[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        widget.timestamp.toDate().toLocal().toString(),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Post Content
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 12.0),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: likePost,
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: isLiked ? Colors.red[700] : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    Text('$likeCount', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    // Comment action
                  },
                  icon: Icon(Icons.comment_outlined, size: 18, color: Theme.of(context).colorScheme.inversePrimary,),
                  label: Text("Comment", style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Share action
                  },
                  icon: Icon(Icons.share_outlined, size: 18, color: Theme.of(context).colorScheme.inversePrimary,),
                  label: Text("Share", style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
