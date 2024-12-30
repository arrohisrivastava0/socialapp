import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/helper/helper_dialogue.dart';
import 'package:socialapp/pages/others_profile_page.dart';
import 'package:socialapp/pages/user_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = "";
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey[850], // Background color for the search bar
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search, color: Colors.grey), // Search icon
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white), // Text color
                    cursorColor: Colors.white, // Cursor color
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey), // Placeholder style
                      border: InputBorder.none, // Removes underline
                    ),

                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .surface,
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("Users").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              displayErrorMessage(
                "Error fetching data", context);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data == null) {
              return const Text("No data");
            }
            final allUsers = snapshot.data!.docs;

            // Apply logic based on whether search query is empty or not
            final filteredUsers = searchQuery.isEmpty
                ? allUsers.where((user) => user.id != currentUserId).toList() // Exclude current user when search is empty
                : allUsers.where((user) =>
            user['username']
                .toString()
                .toLowerCase()
                .contains(searchQuery) || // Match username
                user['name']
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery)) // Match name
                .toList(); // Include all users when searching

            if (filteredUsers.isEmpty) {
              return const Center(
                child: Text("No users found"),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user['username'][0].toUpperCase()),
                        ),
                        title: Text(user["username"]),
                        subtitle: Text(user["name"]),
                        tileColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:BorderRadius.circular(15)
                        ),

                        onTap: () {
                          if(user.id == currentUserId){
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        UserProfilePage()));
                          }
                          else{
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        OthersProfilePage(
                                            userId: user.id)));
                          }

                        },
                      ),
                    );

                  }
              ),
            );
          }
        ),
    );
  }
}
