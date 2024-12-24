import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/pages/others_profile_page.dart';
import 'package:socialapp/pages/user_profile_page.dart';

class ConnectionsListPage extends StatefulWidget {
  final String userId;
  const ConnectionsListPage({super.key, required this.userId});

  @override
  State<ConnectionsListPage> createState() => _ConnectionsListPageState();
}

class _ConnectionsListPageState extends State<ConnectionsListPage> {
  List<Map<String, dynamic>> connections = [];

  @override
  void initState() {
    super.initState();
    fetchAndSetConnections();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   fetchConnections();
  // }

  Future<List<Map<String, dynamic>>> fetchConnections(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('Connections')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        List<dynamic>? to = snapshot.data()?['to'];
        if (to != null) {
          return to.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching connections: $e');
      return [];
    }
  }


  // Future<void> fetchConnections() async {
  //   try {
  //     DocumentSnapshot<Map<String, dynamic>> connectionDoc = await FirebaseFirestore.instance
  //         .collection("Connections")
  //         .doc(widget.userID)
  //         .get();
  //     if (mounted) {
  //       setState(() {
  //         if (connectionDoc.exists && connectionDoc.data() != null){
  //           List<dynamic> connectionsList = connectionDoc.data()!['to'] ?? [];
  //           connections = connectionsList.map((connection) {
  //             final userId = connection.keys.first;  // Assuming there's only one key (userId) in each map
  //             final timestamp = connection[userId];   // Timestamp value associated with userId
  //             return {'userId': userId, 'timestamp': timestamp};
  //           }).toList();
  //         }
  //         else {
  //           connections = [];
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       connections = [];
  //     });
  //   }
  //
  // }

  Future<void> removeConnection(String currentUserId, String connectedUserId) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef =
      FirebaseFirestore.instance.collection('Connections').doc(currentUserId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          List<dynamic> to = snapshot.data()?['to'] ?? [];
          to.removeWhere((item) => item['id'] == connectedUserId);

          transaction.set(docRef, {'to': to}, SetOptions(merge: true));
        }
      });
    } catch (e) {
      print('Error removing connection: $e');
    }
  }

  void fetchAndSetConnections() async {
    List<Map<String, dynamic>> fetchedConnections = await fetchConnections(widget.userId);
    setState(() {
      connections = fetchedConnections;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connections"),
      ),
      body: connections.isEmpty
          ? const Center(child: Text("No connections found."))
          : ListView.builder(
        itemCount: connections.length,
        itemBuilder: (context, index) {
          final connection = connections[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(connection['id'][0].toUpperCase()), // First letter of user ID
            ),
            title: Text(connection['id']),
            subtitle: Text(connection['timestamp']?.toDate().toString() ?? 'No timestamp'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () async {
                await removeConnection(widget.userId, connection['id']);
                fetchAndSetConnections(); // Refresh connections
              },
            ),
            onTap: () {
              // Navigate to the tapped user's profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OthersProfilePage(userId: connection['id'],)
                ),
              );
            },
          );
        },
      ),
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text("Connections"),
  //     ),
  //     body: connections.isEmpty
  //         ? const Center(child: Text("No connections found."))
  //         : ListView.builder(
  //       itemCount: connections.length,
  //       itemBuilder: (context, index) {
  //         final connection = connections[index];
  //         return ListTile(
  //           leading: CircleAvatar(
  //             child: Text(connection['username'][0].toUpperCase()), // Show the first letter of username
  //           ),
  //           title: Text(connection['name'] ?? "Unknown"),
  //           subtitle: Text(connection['username']),
  //           trailing: IconButton(
  //             icon: const Icon(Icons.person_remove_sharp, color: Colors.red),
  //             onPressed: () => removeConnection(connection['id']), // Remove connection
  //           ),
  //           onTap: () {
  //             // Navigate to user's profile
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => OthersProfilePage(userId: connection['id'], username: connection['username'],),
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }
}
