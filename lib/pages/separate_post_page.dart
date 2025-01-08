import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        title: Text("P O S T", style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
            return const Center(child: Text("Post not found."));
          }

          final postData = postSnapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post card
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(postData['username'][0]
                                    .toUpperCase()), // First letter of username
                              ),
                              const SizedBox(width: 10),
                              Text(
                                postData['username'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _timeAgo(postData['timestamp']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            postData['content'] ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(),

                // Comments section
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Comments",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Posts')
                      .doc(widget.postId)
                      .collection('Comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, commentsSnapshot) {
                    if (commentsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!commentsSnapshot.hasData ||
                        commentsSnapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No comments yet."),
                      );
                    }

                    final comments = commentsSnapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final commentData =
                        comments[index].data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(commentData['username'][0]
                                .toUpperCase()), // First letter of username
                          ),
                          title: Text(commentData['username']),
                          subtitle: Text(commentData['content']),
                          trailing: Text(
                            _timeAgo(commentData['timestamp']),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }
}


// StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
// stream: FirebaseFirestore.instance
//     .collection('Posts')
//     .doc(widget.postId)
//     .snapshots(),
// builder: (context, snapshot) {
// if (snapshot.connectionState == ConnectionState.waiting) {
// return const Center(child: CircularProgressIndicator());
// } else if (snapshot.hasError) {
// return const Center(child: Text("Error loading post."));
// } else if (!snapshot.hasData || !snapshot.data!.exists) {
// return const Center(child: Text("GET OUT"));
// }
//
// final posts = snapshot.data!.data()!;
//
// },
// ),


// return ListView.builder(
// itemCount: posts.length,
// itemBuilder: (context, index) {
// final post = posts[index];
// return WallPostTile(
// postId: post['postId'] ?? 'Unknown Post ID',
// content: post['content'] ?? 'No content available',
// username: post['username'] ?? 'Unknown user',
// timestamp: post['timestamp']?? 'No timestamp',
// userId: post['userId'] ?? 'Unknown User ID',
// );
// },
// );
