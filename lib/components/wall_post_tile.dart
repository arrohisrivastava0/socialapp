import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:like_button/like_button.dart';
import 'package:socialapp/pages/user_profile_page.dart';
import '../pages/others_profile_page.dart';
import 'package:http/http.dart' as http;

class WallPostTile extends StatefulWidget {
  final String postId;
  final String content;
  final String username;
  final String userId;
  final Timestamp timestamp;

  const WallPostTile({
    Key? key,
    required this.content,
    required this.username,
    required this.timestamp,
    required this.postId,
    required this.userId,
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


  Future<void> sendPushNotification(String fcmToken, String title, String body) async {
    final serverKey = 'YOUR_SERVER_KEY'; // Obtain this from Firebase Console > Project Settings > Cloud Messaging
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send');

    final message = {
      'message': {
        'token': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully!');
    } else {
      print('Error sending notification: ${response.body}');
    }
  }


  Future<bool> onLikeButtonTapped(bool isLiked) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection("Posts").doc(widget.postId);

    if (isLiked) {
      final postDoc = await postRef.get();
      final likes =
      List<Map<String, dynamic>>.from(postDoc.data()?['likes'] ?? []);
      // Unlike the post
      await postRef.update({
        'likes': FieldValue.arrayRemove([
          likes.firstWhere(
                (like) => like['userId'] == currentUserId,
          )
        ]),
      });
      setState(() {
        this.isLiked = false;
        likeCount -= 1;
      });
    } else {
      // Like the post
      await postRef.update({
        'likes': FieldValue.arrayUnion([
          {'userId': currentUserId, 'timestamp': Timestamp.now()}
        ]),
      });

      final postDoc = await FirebaseFirestore.instance.collection('Posts').doc(widget.postId).get();
      final postOwner = postDoc.data()?['userId'];
      final recUserDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(postOwner)
          .get();
      final token = recUserDoc.data()?['token'];
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .get();
      final username = currentUserDoc.data()?['username'] ?? 'Anonymous';
      if (postOwner != currentUserId){
        if (token != null) {

          await FirebaseFirestore.instance
              .collection('Notifications') // Main collection
              .doc(postOwner) // Document for the recipient user
              .collection('UserNotifications') // Subcollection for user-specific notifications
              .add({ // Automatically generate a unique notificationId
            'type': 'likePost', // Type of notification
            'title': username, // User who liked the post
            'body': "$username just liked your post!", // Notification body
            'postId': widget.postId, // Post ID associated with the like
            'senderId': currentUserId, // The user who liked the post
            'isRead': false, // Notification read status
            'timestamp': Timestamp.now(), // Time of the notification
            'token': token, // FCM token for push notification
          });

          print("\n\n\n\ndone notifying\n\n\n\n");
        }
      }

      setState(() {
        this.isLiked = true;
        likeCount += 1;
      });
    }

    // Return the new state of the button
    return !isLiked;
  }

  Future<void> _checkIfLiked() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final postDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .get();

    if (postDoc.exists) {
      final likes =
          List<Map<String, dynamic>>.from(postDoc.data()?['likes'] ?? []);

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

  Future<void> addComment(String postId, String content) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the user's username
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .get();
    final username = userDoc.data()?['username'] ?? 'Anonymous';

    // Add the comment to the subcollection
    await FirebaseFirestore.instance
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

    final postDoc = await FirebaseFirestore.instance.collection('Posts').doc(postId).get();
    final postOwner = postDoc.data()?['userId'];

    final recUserDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(postOwner)
        .get();
    final token = recUserDoc.data()?['token'];

    // final postDoc = await FirebaseFirestore.instance.collection('Posts').doc(postId).get();
    // final postOwner = postDoc.data()?['userId'];
    final recUsername = postDoc.data()?['username'] ?? 'Anonymous';
    // final token = userDoc.data()?['fcmToken'];

    if (postOwner != currentUserId) {
      if (token != null) {

        await FirebaseFirestore.instance
            .collection('Notifications') // Main collection
            .doc(postOwner) // Document for the recipient user
            .collection('UserNotifications') // Subcollection for notifications
            .add({ // Automatically generate a unique notificationId
          'type': 'comment', // Type of notification
          'title': "$username just commented on your post!", // Notification title
          'body': content, // Comment content
          'postId': postId, // Post ID associated with the comment
          'senderId': currentUserId, // The user who made the comment
          'isRead': false, // Notification read status
          'timestamp': Timestamp.now(), // Time of the notification
          'token': token, // FCM token for push notification
        });

      }
    }
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
    final likes =
        List<Map<String, dynamic>>.from(commentDoc.data()?['likes'] ?? []);
    final isCommentLiked = likes.any((like) => like['userId'] == currentUserId);

    if (isCommentLiked) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove(
            [likes.firstWhere((like) => like['userId'] == currentUserId)]),
      });

    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([
          {'userId': currentUserId, 'timestamp': Timestamp.now()}
        ]),
      });

      final recId= commentDoc.data()?['userId'];
      final recUserDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(recId)
          .get();
      final token = recUserDoc.data()?['token'];
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId)
          .get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';

      // final postDoc = await FirebaseFirestore.instance.collection('Posts').doc(widget.postId).get();
      final postOwner = widget.username;

      if (recId != currentUserId){
        if (token != null) {

          await FirebaseFirestore.instance
              .collection('Notifications') // Main collection
              .doc(recId) // Document for recipient user
              .collection('UserNotifications') // Subcollection for notifications
              .add({ // Automatically generate a notificationId
            'type': 'likeComment', // Type of notification (e.g., 'like', 'comment')
            'title': username, // Notification title
            'body': "$username just liked your comment on $postOwner's post!", // Notification body
            'postId': widget.postId, // Optional post ID
            'senderId': currentUserId, // The user who triggered the notification
            'isRead': false, // Notification read status
            'timestamp': Timestamp.now(), // Time of the notification
            'token':token
          });
        }
      }
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
                      color: Theme.of(context).colorScheme.inversePrimary,
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
                            final isCommentLiked =
                                List<Map<String, dynamic>>.from(
                                        comment['likes'] ?? [])
                                    .any((like) =>
                                        like['userId'] ==
                                        FirebaseAuth.instance.currentUser!.uid);
                            final commentLikeCount =
                                (comment['likes'] as List?)?.length ?? 0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                radius: 15,
                                child: Text(
                                  comment['username'][0].toUpperCase(),
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                              title: Row(
                                children: [
                                  GestureDetector(
                                    child: Text(comment['username']),
                                    onTap: () {
                                      if (comment['userId'] ==
                                          FirebaseAuth
                                              .instance.currentUser!.uid) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    UserProfilePage()));
                                      } else {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    OthersProfilePage(
                                                        userId: comment[
                                                            'userId'])));
                                      }
                                    },
                                  ),
                                  Text(
                                    timeAgo(widget.timestamp),
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
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
                                          ? Colors.pink[300]
                                          : Theme.of(context).colorScheme.inversePrimary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$commentLikeCount',
                                    // Replace with your like count
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.inversePrimary, // Adjust color
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

  String timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inSeconds < 60) {
      return ' ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return ' ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return ' ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return ' ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return ' ${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return ' ${(difference.inDays / 30).floor()}mo';
    } else {
      return ' ${(difference.inDays / 365).floor()}y';
    }
  }

  Future<void> sendNotification(String recipientId, String title, String body) async {
    final tokenDoc = await FirebaseFirestore.instance.collection('Users').doc(recipientId).get();
    final token = tokenDoc.data()?['fcmToken']; // Ensure each user saves their FCM token in Firestore during sign-up or login

    if (token != null) {
      await FirebaseFirestore.instance.collection('Notifications').doc('Likes').set({
        'token': token,
        'title': title,
        'body': body,
        'timestamp': Timestamp.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.onPrimary,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 10,
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
                      GestureDetector(
                        onTap: () {
                          if (widget.userId ==
                              FirebaseAuth.instance.currentUser!.uid) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => UserProfilePage()));
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OthersProfilePage(
                                        userId: widget.userId)));
                          }
                        },
                        child: Text(
                          widget.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${timeAgo(widget.timestamp)} ago',
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
            const SizedBox(height: 14.0),

            // Post Content
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 17.0,
              ),
            ),
            const SizedBox(height: 12.0),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    LikeButton(
                      animationDuration: const Duration(milliseconds: 800),
                      isLiked: isLiked,
                      likeCount: likeCount,
                      onTap: onLikeButtonTapped,
                      circleColor: const CircleColor(
                          start: Color(0xFF79173D), end: Color(0xFFFF0777)),
                      bubblesColor: const BubblesColor(
                          dotPrimaryColor: Color(0xFFDA81B8),
                          dotSecondaryColor: Color(0xFFD94E76),
                          dotThirdColor: Color(0xFFAF1C5C),
                          dotLastColor: Color(0xFF911942)),
                      likeBuilder: (bool isLiked) {
                        if(isLiked){
                          return Icon(
                            Icons.favorite,
                            color: Colors.pink[300],
                            size: 25,
                          );
                        }
                        else{
                          return Icon(
                            Icons.favorite_outline,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            size: 25,
                          );
                        }
                      },
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
