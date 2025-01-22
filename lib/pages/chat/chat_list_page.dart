import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/components/user_tile.dart';
import 'package:socialapp/pages/chat/chat_room_page.dart';
import 'package:socialapp/pages/chat/chat_service.dart';

class ChatListPage extends StatefulWidget {
  ChatListPage({Key? key}) : super(key: key);

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  final ChatService _chatService = ChatService();

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
                hintText: 'Search for chats or connections...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Show search results if searchQuery is not empty
          if (searchQuery.isNotEmpty) Expanded(child: _buildSearchResults()),

          // Show Chats and Connections sections if no search is performed
          if (searchQuery.isEmpty) Expanded(child: _buildChatsAndConnections()),
        ],
      ),
    );
  }

  Widget _buildChatsAndConnections() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chats Section
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Chats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildChatList(),

          // Connections Section
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Connections',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildConnectionList(),
        ],
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox.shrink(); // Or return an empty container
        }


        final chats = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUserId = (chat['participants'] as List)
                .firstWhere((id) => id != widget.currentUserId);

            return FutureBuilder<String>(
              future: _getUsername(otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }
                final username = snapshot.data ?? 'Unknown';
                return UserTile(
                  uid: otherUserId,
                  name: chat['lastMessage'],
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
      },
    );
  }

  Widget _buildConnectionList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('No connections found.'),
          );
        }

        final data = snapshot.data!;
        final connections = List<String>.from(data['connections'] ?? []);

        if (connections.isEmpty) {
          return const Center(
            child: Text('You have no connections yet.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final otherUserId = connections[index];

            return FutureBuilder<String>(
              future: _getUsername(otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }
                final username = snapshot.data ?? 'Unknown';
                return UserTile(
                  uid: otherUserId,
                  onTap: () {
                    _createChatDoc(otherUserId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          chatId: "${widget.currentUserId}_$otherUserId",
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        final users = snapshot.data!.docs
            .where((user) => user.id != widget.currentUserId)
            .toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final otherUserId = user.id;

            return UserTile(
              uid: otherUserId,
              name: user['username'],
              onTap: () {
                _createChatDoc(otherUserId);
                // _chatService.startChat(
                //   currentUserId: widget.currentUserId,
                //   otherUserId: otherUserId,
                //   context: context,
                // );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _getUsername(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    return userDoc.data()?['username'] ?? 'Unknown';
  }

  Future<void> _createChatDoc(String otherUserId) async {

    await FirebaseFirestore.instance
        .collection("Chat")
        .doc("${widget.currentUserId}_$otherUserId")
        .set({
      'lastMessage': " ",
      'lastUpdated': " ",
      'participants': [widget.currentUserId, otherUserId],
    });
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:socialapp/components/user_tile.dart';
// import 'package:socialapp/pages/chat/chat_room_page.dart';
// import 'package:socialapp/pages/chat/chat_service.dart';
//
// class ChatListPage extends StatefulWidget {
//   ChatListPage({Key? key}) : super(key: key);
//
//   final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
//
//   @override
//   State<ChatListPage> createState() => _ChatListPageState();
// }
//
// class _ChatListPageState extends State<ChatListPage> {
//   String searchQuery = '';
//   final TextEditingController searchController = TextEditingController();
//   final ChatService _chatService = ChatService();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chats'),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(50),
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: searchController,
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value;
//                 });
//               },
//               decoration: InputDecoration(
//                 hintText: 'Search for connections...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: searchQuery.isEmpty ? _buildChatList() : _buildSearchResults(),
//     );
//   }
//
//   Widget _buildChatList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('Chats')
//           .where('participants', arrayContains: widget.currentUserId)
//           .orderBy('lastUpdated', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text('No chats yet. Start a conversation!'));
//         }
//
//         final chats = snapshot.data!.docs;
//
//         return Expanded(
//           child: ListView.builder(
//             itemCount: chats.length,
//             itemBuilder: (context, index) {
//               final chat = chats[index];
//               final otherUserId = (chat['participants'] as List)
//                   .firstWhere((id) => id != widget.currentUserId);
//
//               return FutureBuilder<String>(
//                 future: _getUsername(otherUserId),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const ListTile(
//                       title: Text('Loading...'),
//                     );
//                   }
//                   final username = snapshot.data ?? 'Unknown';
//                   return UserTile(
//                     uid: otherUserId,
//                     name: chat['lastMessage'],
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ChatRoomPage(
//                             chatId: chat.id,
//                             currentUserId: widget.currentUserId,
//                             otherUserId: otherUserId,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSearchResults() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('Users')
//           .where('username', isGreaterThanOrEqualTo: searchQuery)
//           .where('username', isLessThanOrEqualTo: '${searchQuery}z')
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text('No users found.'));
//         }
//
//         final users = snapshot.data!.docs
//             .where((user) => user.id != widget.currentUserId)
//             .toList();
//
//         return Expanded(
//           child: ListView.builder(
//             itemCount: users.length,
//             itemBuilder: (context, index) {
//               final user = users[index];
//               final otherUserId = user.id;
//
//               return UserTile(
//                 uid: otherUserId,
//                 onTap: () {
//                   // // Handle starting a chat with the selected user
//                   // _chatService.startChat(
//                   //   currentUserId: widget.currentUserId,
//                   //   otherUserId: otherUserId,
//                   //   context: context,
//                   // );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Future<String> _getUsername(String userId) async {
//     final userDoc =
//     await FirebaseFirestore.instance.collection('Users').doc(userId).get();
//     return userDoc.data()?['username'] ?? 'Unknown';
//   }
// }
//
//

// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:socialapp/pages/chat_room_page.dart';
// //
// // class ChatListPage extends StatelessWidget {
// //
// //
// //   ChatListPage({super.key,});
// //   final String? currentUserId= FirebaseAuth.instance.currentUser?.uid;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //           title: const Text('Chats'),
// //         backgroundColor: Theme.of(context).colorScheme.onPrimary,
// //       ),
// //       body: StreamBuilder<QuerySnapshot>(
// //         stream: FirebaseFirestore.instance
// //             .collection('Chats')
// //             .where('participants', arrayContains: currentUserId)
// //             .orderBy('lastUpdated', descending: true)
// //             .snapshots(),
// //         builder: (context, snapshot) {
// //           if (!snapshot.hasData) return const Center(child: Text("Your imaginary friends won't show up here"));
// //
// //           final chats = snapshot.data!.docs;
// //
// //           return ListView.builder(
// //             itemCount: chats.length,
// //             itemBuilder: (context, index) {
// //               final chat = chats[index];
// //               final otherUserId = (chat['participants'] as List)
// //                   .firstWhere((id) => id != currentUserId);
// //
// //               return ListTile(
// //                 title: Text('Chat with $otherUserId'), // Replace with username
// //                 subtitle: Text(chat['lastMessage']),
// //                 onTap: () {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => ChatRoomPage(
// //                         chatId: chat.id,
// //                         currentUserId: currentUserId ?? "",
// //                         otherUserId: otherUserId,
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               );
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:socialapp/components/user_tile.dart';
// import 'package:socialapp/pages/chat/chat_room_page.dart';
// import 'package:socialapp/pages/chat/chat_service.dart';
//
// import '../../helper/helper_dialogue.dart';
//
// class ChatListPage extends StatefulWidget {
//   ChatListPage({
//     super.key,
//   });
//
//   final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
//
//   @override
//   State<ChatListPage> createState() => _ChatListPageState();
// }
//
// class _ChatListPageState extends State<ChatListPage> {
//   String searchQuery = '';
//   TextEditingController searchController = TextEditingController();
//   final ChatService _chatService = ChatService();
//
//   // Future<void> startChat(String otherUserId) async {
//   //   // Fetch chats where the current user is a participant
//   //   final chatsQuery = await FirebaseFirestore.instance
//   //       .collection('Chats')
//   //       .doc(widget.currentUserId)
//   //   // .where('participants', arrayContains: widget.currentUserId)
//   //       .get();
//   //
//   //   // Find an existing chat with the other user
//   //   QueryDocumentSnapshot<Map<String, dynamic>>? existingChat;
//   //   {
//   //     if ((chatsQuery['participants'] as List).contains(otherUserId)) {
//   //       existingChat = doc;
//   //     }
//   //   }
//   //
//   //   String chatId;
//   //   if (existingChat != null) {
//   //     // If a chat exists, get its ID
//   //     chatId = existingChat.id;
//   //   } else {
//   //     // Create a new chat if no existing chat found
//   //     final newChatRef = FirebaseFirestore.instance.collection('Chats').doc(
//   //         widget.currentUserId);
//   //     await newChatRef.set({
//   //       'participants': [widget.currentUserId, otherUserId],
//   //       'lastMessage': '',
//   //       'lastUpdated': Timestamp.now(),
//   //     });
//   //     chatId = newChatRef.id;
//   //   }
//   //
//   //   // Navigate to the Chat Room page
//   //   Navigator.push(
//   //     context,
//   //     MaterialPageRoute(
//   //       builder: (context) =>
//   //           ChatRoomPage(
//   //             chatId: chatId,
//   //             currentUserId: widget.currentUserId,
//   //             otherUserId: otherUserId,
//   //           ),
//   //     ),
//   //   );
//   // }
//
//   Future<String> getUsername(String userId) async {
//     final tokenDoc =
//     await FirebaseFirestore.instance.collection('Users').doc(userId).get();
//     return tokenDoc.data()?['username'];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chats'),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(50),
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: searchController,
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value;
//                 });
//               },
//               decoration: InputDecoration(
//                 hintText: 'Search for connections...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       // body: searchQuery.isEmpty ? _buildChatList() : _buildSearchResults(),
//       body: Column(
//         children: [
//           searchQuery.isEmpty ? _buildChatList() : _buildSearchResults(),
//           _buildConnectionList()
//         ],
//       ),
//     );
//   }
//
//   Widget _buildConnectionList() {
//     return StreamBuilder(
//         stream: _chatService.fetchConnections(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(
//                 child: Text("Your imaginary friends won't show up here"));
//           }
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           if (snapshot.data == null) {
//             return const Text("No data");
//           }
//           final connectedUsersDoc = snapshot.data!;
//           final List<dynamic> toList = connectedUsersDoc.data()?['to'] ?? [];
//           final connectedUsers =
//           toList.map((id) => {'id': id, 'timestamp': null}).toList();
//           return ListView.builder(
//             itemCount: connectedUsers.length,
//             itemBuilder: (context, index) {
//               final connection = connectedUsers[index];
//               return UserTile(uid: connection['id']);
//               // return ListTile(
//               //   leading: CircleAvatar(
//               //     child: Text(connection['id'][0].toUpperCase()),
//               //   ),
//               //   title: Text(connection['id']),
//               //   onTap: () {
//               //     Navigator.push(
//               //       context,
//               //       MaterialPageRoute(
//               //         builder: (context) =>
//               //             ChatRoomPage(chatId: '', currentUserId: '', otherUserId: '',),
//               //       ),
//               //     );
//               //   },
//               // );
//             },
//           );
//         });
//   }
//
//   Widget _buildChatList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('Chats')
//           .where('participants', arrayContains: widget.currentUserId)
//           .orderBy('lastUpdated', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(
//               child: Text("Your imaginary friends won't show up here"));
//         }
//         final chats = snapshot.data!.docs;
//         if (chats.isEmpty) {
//           return const Center(
//               child: Text('No chats yet. Start a conversation!'));
//         }
//
//         return ListView.builder(
//           itemCount: chats.length,
//           itemBuilder: (context, index) {
//             final chat = chats[index];
//             final otherUserId = (chat['participants'] as List)
//                 .firstWhere((id) => id != widget.currentUserId);
//             final username = getUsername(otherUserId);
//             return UserTile(
//               uid: otherUserId,
//               name: chat['lastMessage'],
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         ChatRoomPage(
//                           chatId: chat.id,
//                           currentUserId: widget.currentUserId,
//                           otherUserId: otherUserId,
//                         ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildSearchResults() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('Users')
//           .where('username', isGreaterThanOrEqualTo: searchQuery)
//           .where('username', isLessThanOrEqualTo: '${searchQuery}z')
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(
//               child: Text("Your imaginary friends won't show up here"));
//         }
//         final users = snapshot.data!.docs
//             .where((user) => user.id != widget.currentUserId)
//             .toList();
//         if (users.isEmpty) {
//           return const Center(child: Text('No users found.'));
//         }
//         return ListView.builder(
//           itemCount: users.length,
//           itemBuilder: (context, index) {
//             final user = users[index];
//             final otherUserId = user.id;
//             // Prevent the current user from chatting with themselves
//             if (otherUserId == widget.currentUserId) {
//               return const SizedBox.shrink();
//             }
//             return UserTile(
//               uid: otherUserId,
//               onTap: () {},
//             );
//
//             return ListTile(
//               title: Text(user['username']),
//               leading: CircleAvatar(
//                 backgroundColor: Theme
//                     .of(context)
//                     .colorScheme
//                     .inversePrimary,
//                 radius: 20,
//                 child: Text(
//                   user['username'].isNotEmpty
//                       ? user['username'][0].toUpperCase()
//                       : '?',
//                   style: const TextStyle(fontSize: 20),
//                 ),
//               ),
//               onTap: () {},
//             );
//           },
//         );
//       },
//     );
//   }
// }
