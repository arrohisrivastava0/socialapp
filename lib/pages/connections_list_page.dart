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

  Future<List<Map<String, dynamic>>> fetchConnections() async {
    try {
      final connectionDoc = await FirebaseFirestore.instance
          .collection('Connections')
          .doc(widget.userId)
          .get();

      if (connectionDoc.exists) {
        // Assuming 'to' is a list of user IDs
        final List<dynamic> toList = connectionDoc.data()?['to'] ?? [];
        return toList.map((id) => {'id': id, 'timestamp': null}).toList();
      }
    } catch (e) {
      print('Error fetching connections: $e');
    }
    return [];
  }



  Future<void> removeConnection(String connectedUserId) async {
    try {
      final docRef =
      FirebaseFirestore.instance.collection('Connections').doc(widget.userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final List<dynamic> to = snapshot.data()?['to'] ?? [];
          to.remove(connectedUserId);
          transaction.update(docRef, {'to': to});
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection removed successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove connection: $e")),
      );
    }
  }


  void fetchAndSetConnections() async {
    connections = await fetchConnections();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connections"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchConnections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading connections."));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No connections found."));
          }

          final connections = snapshot.data!;
          return ListView.builder(
            itemCount: connections.length,
            itemBuilder: (context, index) {
              final connection = connections[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(connection['id'][0].toUpperCase()),
                ),
                title: Text(connection['id']),
                subtitle: Text(connection['timestamp']?.toDate()?.toString() ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () async {
                    await removeConnection(connection['id']);
                    fetchAndSetConnections();
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OthersProfilePage(userId: connection['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

}
