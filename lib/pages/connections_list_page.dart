import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/pages/others_profile_page.dart';

class ConnectionsListPage extends StatefulWidget {
  final String userID;
  const ConnectionsListPage({super.key, required this.userID});

  @override
  State<ConnectionsListPage> createState() => _ConnectionsListPageState();
}

class _ConnectionsListPageState extends State<ConnectionsListPage> {
  List<Map<String, dynamic>> connections = [];

  @override
  void initState() {
    super.initState();
    fetchConnections();
  }

  Future<void> fetchConnections() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> connectionDoc = await FirebaseFirestore.instance
          .collection("Connections")
          .doc(widget.userID)
          .get();
      if (mounted) {
        setState(() {
          if (connectionDoc.exists && connectionDoc.data() != null){
            List<dynamic> connectionsList = connectionDoc.data()!['to'] ?? [];
            connections = connectionsList.map((connection) {
              final userId = connection.keys.first;  // Assuming there's only one key (userId) in each map
              final timestamp = connection[userId];   // Timestamp value associated with userId
              return {'userId': userId, 'timestamp': timestamp};
            }).toList();
          }
          else {
            connections = [];
          }
        });
      }
    } catch (e) {
      setState(() {
        connections = [];
      });
    }

  }

  Future<void> removeConnection(String connectionId) async {
    try {
      await FirebaseFirestore.instance
          .collection("Connections")
          .doc(widget.userID)
          .update({
        'to': FieldValue.arrayRemove([{
          connectionId: FieldValue.serverTimestamp()  // Remove the specific map {userId: Timestamp}
        }])
      });

      fetchConnections(); // Refresh connections
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection removed successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to remove connection")),
      );
    }
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
              child: Text(connection['username'][0].toUpperCase()), // Show the first letter of username
            ),
            title: Text(connection['name'] ?? "Unknown"),
            subtitle: Text(connection['username']),
            trailing: IconButton(
              icon: const Icon(Icons.person_remove_sharp, color: Colors.red),
              onPressed: () => removeConnection(connection['id']), // Remove connection
            ),
            onTap: () {
              // Navigate to user's profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OthersProfilePage(userId: connection['id'], username: connection['username'],),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
