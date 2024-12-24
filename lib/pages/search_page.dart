import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/helper/helper_dialogue.dart';
import 'package:socialapp/pages/others_profile_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Search', style: TextStyle(color: Theme
              .of(context)
              .colorScheme
              .surface),),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
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

            final users = snapshot.data!.docs;
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: ListTile(
                        title: Text(user["username"]),
                        subtitle: Text(user["name"]),
                        tileColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:BorderRadius.circular(15)
                        ),

                        onTap: (){
                          Navigator.push(
                              context, 
                              MaterialPageRoute(
                                  builder: (context) => OthersProfilePage(userId: user.id, username: user['username'])
                              )
                          );
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
