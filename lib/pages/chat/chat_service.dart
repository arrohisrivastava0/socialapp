import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService{
  final FirebaseFirestore _firestore= FirebaseFirestore.instance;

  // Stream<List<Map<String, dynamic>>> getUserStream(){
  //   return _firestore.collection("Connections").snapshots().map((snapshot) {
  //     return snapshot.docs.map(toElement)
  //   });
  // }

  Stream<DocumentSnapshot<Map<String, dynamic>>> fetchConnections() {
    final currentUserId=FirebaseAuth.instance.currentUser!.uid;
    return _firestore.collection("Connections").doc(currentUserId).snapshots();
    // try {
    //   final connectionDoc = await FirebaseFirestore.instance
    //       .collection('Connections')
    //       .doc(currentUserId)
    //       .get();
    //
    //   if (connectionDoc.exists) {
    //     // Assuming 'to' is a list of user IDs
    //     final List<dynamic> toList = connectionDoc.data()?['to'] ?? [];
    //     return toList.map((id) => {'id': id, 'timestamp': null}).toList();
    //   }
    // } catch (e) {
    //   print('Error fetching connections: $e');
    // }
    // return [];
  }
}