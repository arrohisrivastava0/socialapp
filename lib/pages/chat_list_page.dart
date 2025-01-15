// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:socialapp/pages/chat_room_page.dart';
//
// class ChatListPage extends StatelessWidget {
//
//
//   ChatListPage({super.key,});
//   final String? currentUserId= FirebaseAuth.instance.currentUser?.uid;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           title: const Text('Chats'),
//         backgroundColor: Theme.of(context).colorScheme.onPrimary,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('Chats')
//             .where('participants', arrayContains: currentUserId)
//             .orderBy('lastUpdated', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const Center(child: Text("Your imaginary friends won't show up here"));
//
//           final chats = snapshot.data!.docs;
//
//           return ListView.builder(
//             itemCount: chats.length,
//             itemBuilder: (context, index) {
//               final chat = chats[index];
//               final otherUserId = (chat['participants'] as List)
//                   .firstWhere((id) => id != currentUserId);
//
//               return ListTile(
//                 title: Text('Chat with $otherUserId'), // Replace with username
//                 subtitle: Text(chat['lastMessage']),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ChatRoomPage(
//                         chatId: chat.id,
//                         currentUserId: currentUserId ?? "",
//                         otherUserId: otherUserId,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/pages/chat_room_page.dart';

class ChatListPage extends StatefulWidget {


  ChatListPage({super.key,});
  final String currentUserId= FirebaseAuth.instance.currentUser!.uid;

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  Future<void> startChat(String otherUserId) async {
    // Fetch chats where the current user is a participant
    final chatsQuery = await FirebaseFirestore.instance
        .collection('Chats')
        .where('participants', arrayContains: widget.currentUserId)
        .get();

    // Find an existing chat with the other user
    QueryDocumentSnapshot<Map<String, dynamic>>? existingChat;
    for (var doc in chatsQuery.docs) {
      if ((doc['participants'] as List).contains(otherUserId)) {
        existingChat = doc;
        break;
      }
    }

    String chatId;
    if (existingChat != null) {
      // If a chat exists, get its ID
      chatId = existingChat.id;
    } else {
      // Create a new chat if no existing chat found
      final newChatRef = FirebaseFirestore.instance.collection('Chats').doc();
      await newChatRef.set({
        'participants': [widget.currentUserId, otherUserId],
        'lastMessage': '',
        'lastUpdated': Timestamp.now(),
      });
      chatId = newChatRef.id;
    }

    // Navigate to the Chat Room page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          chatId: chatId,
          currentUserId: widget.currentUserId,
          otherUserId: otherUserId,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for connections...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      body: searchQuery.isEmpty
          ? _buildChatList()
          : _buildSearchResults(),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Chats')
          .where('participants', arrayContains: widget.currentUserId)
          .orderBy('lastUpdated', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: Text("Your imaginary friends won't show up here"));

        final chats = snapshot.data!.docs;
        if (chats.isEmpty) {
          return const Center(child: Text('No chats yet. Start a conversation!'));
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUserId = (chat['participants'] as List)
                .firstWhere((id) => id != widget.currentUserId);

            return ListTile(
              title: Text('Chat with $otherUserId'), // Replace with username
              subtitle: Text(chat['lastMessage']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomPage(
                      chatId: chat.id,
                      currentUserId: widget.currentUserId,
                      otherUserId: otherUserId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThanOrEqualTo: '${searchQuery}z')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: Text("Your imaginary friends won't show up here"));

        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final otherUserId = user.id;

            // Prevent the current user from chatting with themselves
            if (otherUserId == widget.currentUserId) return const SizedBox.shrink();

            return ListTile(
              title: Text(user['username']),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                radius: 20,
                child: Text(
                  user['username'].isNotEmpty
                      ? user['username'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              onTap: () => startChat(user["username"]),
            );
          },
        );
      },
    );
  }
}
