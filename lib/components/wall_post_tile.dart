import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WallPostTile extends StatelessWidget {
  final String content;
  final String userId;
  final Timestamp timestamp;

  const WallPostTile({
    Key? key,
    required this.content,
    required this.userId,
    required this.timestamp,
  }) : super(key: key);

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
                    userId.isNotEmpty ? userId[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        timestamp.toDate().toLocal().toString(),
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
              content,
              style: const TextStyle(
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 12.0),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Like action
                  },
                  icon: Icon(Icons.thumb_up_alt_outlined, size: 18, color: Theme.of(context).colorScheme.inversePrimary,),
                  label: Text("Like", style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
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
