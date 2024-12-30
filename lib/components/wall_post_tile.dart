import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/others_profile_page.dart';

class WallPostTile extends StatefulWidget {
  final String postId;
  final String content;
  final String username;
  final Timestamp timestamp;

  const WallPostTile({
    Key? key,
    required this.content,
    required this.username,
    required this.timestamp,
    required this.postId,
  }) : super(key: key);

  @override
  State<WallPostTile> createState() => _WallPostTileState();
}

class _WallPostTileState extends State<WallPostTile> {
  final TextEditingController commentTextController = TextEditingController();
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _fetchCommentCount();
  }


  Future<void> _checkIfLiked() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final postDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .get();

    if (postDoc.exists) {
      final likes = List<Map<String, dynamic>>.from(postDoc.data()?['likes'] ?? []);

      setState(() {
        isLiked = likes.any((like) => like['userId'] == currentUserId);
        likeCount = likes.length;
      });
    }
  }

  Future<void> _fetchCommentCount() async {
    final commentSnapshot = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .collection('Comments')
        .get();

    setState(() {
      commentCount = commentSnapshot.docs.length;
    });
  }

  Future<void> likePost() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection("Posts").doc(widget.postId);
    if (isLiked) {
      final postDoc = await postRef.get();
      final likes = List<Map<String, dynamic>>.from(postDoc.data()?['likes'] ?? []);
      // Unlike the post
      await postRef.update({
        'likes': FieldValue.arrayRemove([likes.firstWhere(
      (like) => like['userId'] == currentUserId,)]),
      });
      setState(() {
        isLiked = false;
        likeCount -= 1;
      });
    }
    else {
      // Like the post
      await postRef.update({
        'likes': FieldValue.arrayUnion([{'userId': currentUserId, 'timestamp': Timestamp.now()}]),
      });
      setState(() {
        isLiked = true;
        likeCount += 1;
      });
    }
  }

  Future<void> addComment(String postId, String content) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the user's username
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .get();
    final username = userDoc.data()?['username'] ?? 'Anonymous';

    // Add the comment to the subcollection
    final commentRef =await FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .add({
      'userId': currentUserId,
      'username': username,
      'content': content,
      'timestamp': Timestamp.now(),
      'likes': [],
    });

    await _fetchCommentCount();
  }

  Future<void> likeComment(String commentId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final commentRef = FirebaseFirestore.instance
        .collection("Posts")
        .doc(widget.postId)
        .collection('Comments')
        .doc(commentId);

    final commentDoc = await commentRef.get();
    final likes = List<Map<String, dynamic>>.from(commentDoc.data()?['likes'] ?? []);
    final isCommentLiked = likes.any((like) => like['userId'] == currentUserId);

    if (isCommentLiked) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove([
          likes.firstWhere((like) => like['userId'] == currentUserId)
        ]),
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([
          {'userId': currentUserId, 'timestamp': Timestamp.now()}
        ]),
      });
    }
  }

  void showCommentsBottomSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Adjust for keyboard
              ),
              child: Column(
                children: [
                  Container(
                    height: 5,
                    width: 40,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Posts')
                          .doc(postId)
                          .collection('Comments')
                          .orderBy('timestamp', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(
                              child: Text("Error loading comments"));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No comments yet."));
                        }

                        final comments = snapshot.data!.docs;
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment =
                                comments[index].data() as Map<String, dynamic>;
                            final commentId = comments[index].id;
                            final isCommentLiked = List<Map<String, dynamic>>
                                .from(comment['likes'] ?? [])
                                .any((like) => like['userId'] ==
                                FirebaseAuth.instance.currentUser!.uid);
                            final commentLikeCount =
                                (comment['likes'] as List?)?.length ?? 0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                                radius: 15,
                                child: Text(comment['username'][0].toUpperCase(), style: TextStyle(fontSize: 15),),
                              ),
                              title: GestureDetector(
                                child: Text(comment['username']),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              OthersProfilePage(
                                                  userId: comment['userId'])));
                                },
                              ),
                              // title: Text(comment['username']),
                              subtitle: Text(comment['content']),

                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      await likeComment(commentId);
                                    },
                                    child: Icon(
                                      isCommentLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isCommentLiked
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$commentLikeCount', // Replace with your like count
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey, // Adjust color
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentTextController,
                            decoration: const InputDecoration(
                              hintText: "Add a comment...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary),
                          onPressed: () async {
                            if (commentTextController.text.isNotEmpty) {
                              await addComment(
                                  postId, commentTextController.text);
                              commentTextController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                  radius: 20,
                  child: Text(
                    widget.username.isNotEmpty
                        ? widget.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        widget.timestamp.toDate().toLocal().toString(),
                        style: TextStyle(
                          fontSize: 14.0,
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
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? Colors.red[700]
                            : Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    Text(
                      '$likeCount',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => showCommentsBottomSheet(widget.postId),
                      icon: Icon(
                        Icons.comment_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    Text(
                      '$commentCount',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary),
                    ),
                  ],
                ),
                // TextButton.icon(
                //   onPressed: () => showCommentsBottomSheet(widget.postId),
                //   icon: Icon(Icons.comment_outlined, size: 18, color: Theme.of(context).colorScheme.inversePrimary,),
                //   label: Text("Comment", style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
                // ),
                TextButton.icon(
                  onPressed: () {
                    // Share action
                  },
                  icon: Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  label: Text(
                    "Share",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
