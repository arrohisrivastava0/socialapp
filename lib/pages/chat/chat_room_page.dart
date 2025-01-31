// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// class ChatRoomPage extends StatefulWidget {
//   final String chatId;
//   final String currentUserId;
//   final String otherUserId;
//
//   const ChatRoomPage({
//     super.key,
//     required this.chatId,
//     required this.currentUserId,
//     required this.otherUserId,
//   });
//
//   @override
//   State<ChatRoomPage> createState() => _ChatRoomPageState();
// }
//
// class _ChatRoomPageState extends State<ChatRoomPage> {
//   final TextEditingController _messageController = TextEditingController();
//
//   Future<void> sendMessage() async {
//     if (_messageController.text.isEmpty) return;
//
//     final message = {
//       'senderId': widget.currentUserId,
//       'text': _messageController.text,
//       'timestamp': Timestamp.now(),
//       'isRead': false,
//     };
//
//     await FirebaseFirestore.instance
//         .collection('Chats')
//         .doc(widget.chatId)
//         .collection('Messages')
//         .add(message);
//
//     await FirebaseFirestore.instance
//         .collection('Chats')
//         .doc(widget.chatId)
//         .update({
//       'lastMessage': _messageController.text,
//       'lastUpdated': Timestamp.now(),
//     });
//
//     _messageController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Chat with ${widget.otherUserId}')),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('Chats')
//                   .doc(widget.chatId)
//                   .collection('Messages')
//                   .orderBy('timestamp')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const Center(child: Text('No chats yet. Start a conversation!'));
//
//                 final messages = snapshot.data!.docs;
//
//                 return ListView.builder(
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     final message = messages[index];
//                     final isMe = message['senderId'] == widget.currentUserId;
//
//                     return Align(
//                       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                       child: Container(
//                         padding: const EdgeInsets.all(10),
//                         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                         decoration: BoxDecoration(
//                           color: isMe ? Colors.blue : Colors.grey[300],
//                           borderRadius: BorderRadius.only(
//                             topLeft: const Radius.circular(10),
//                             topRight: const Radius.circular(10),
//                             bottomLeft: isMe ? const Radius.circular(10) : Radius.zero,
//                             bottomRight: isMe ? Radius.zero : const Radius.circular(10),
//                           ),
//                         ),
//                         child: Text(
//                           message['text'],
//                           style: TextStyle(
//                             color: isMe ? Colors.white : Colors.black,
//                           ),
//                         ),
//                       ),
//                     );
//
//
//                     // return Align(
//                     //   alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                     //   child: Container(
//                     //     padding: const EdgeInsets.all(10),
//                     //     margin: const EdgeInsets.all(5),
//                     //     decoration: BoxDecoration(
//                     //       color: isMe ? Colors.blue : Colors.grey,
//                     //       borderRadius: BorderRadius.circular(10),
//                     //     ),
//                     //     child: Text(
//                     //       message['text'],
//                     //       style: const TextStyle(color: Colors.white),
//                     //     ),
//                     //   ),
//                     // );
//                   },
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: const InputDecoration(
//                       hintText: 'Type a message...',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final message = {
      'senderId': widget.currentUserId,
      'text': _messageController.text,
      'timestamp': Timestamp.now(),
      'isRead': false,
    };

    try {
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .collection('Messages')
          .add(message);

      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': _messageController.text,
        'lastUpdated': Timestamp.now(),
      });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.otherUserId}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Chats')
                  .doc(widget.chatId)
                  .collection('Messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Text('No chats yet. Start a conversation!'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}