import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
            .collection('UserNotifications')
            .orderBy('timestamp', descending: true)
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

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index].data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    tileColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius:BorderRadius.circular(15)
                    ),

                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                      child: Text(notification['username'][0].toUpperCase()),
                    ),
                    title: Text(notification['title'] ?? "No Title"),
                    subtitle: Text(notification['body'] ?? "No Message"),
                    trailing: notification['isRead'] == false
                        ? Icon(Icons.circle, color: Colors.pink[400], size: 10)
                        : null,
                    onTap: () {
                      // Mark notification as read
                      FirebaseFirestore.instance
                          .collection('Notifications')
                          .doc(currentUserId)
                          .collection('UserNotifications')
                          .doc(notifications[index].id)
                          .update({'isRead': true});

                      // Navigate to PostPage
                      if (notification['postId'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeparatePostPage(postId: notification['postId']),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
