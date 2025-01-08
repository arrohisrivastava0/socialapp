import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialapp/pages/separate_post_page.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .doc(currentUserId)
            .collection('LikeComment') // Adjust for other subcollections if needed
            .orderBy('timestamp', descending: true) // Latest notifications first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications"));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(notification['title'] ?? "No Title"),
                subtitle: Text(notification['message'] ?? "No Message"),
                trailing: notification['isRead'] == false
                    ? Icon(Icons.circle, color: Colors.red, size: 10)
                    : null,
                onTap: () {
                  // Mark as read
                  FirebaseFirestore.instance
                      .collection('Notifications')
                      .doc(currentUserId)
                      .collection('LikeComment')
                      .doc(notifications[index].id)
                      .update({'isRead': true});

                  // Navigate to the related post or profile
                  if (notification['postId'] != null) {
                    // Example: Navigate to PostPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeparatePostPage(postId: notification['postId']),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
