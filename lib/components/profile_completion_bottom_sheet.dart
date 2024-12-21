import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:socialapp/components/my_textfield.dart';

class ProfileCompletionBottomSheet extends StatefulWidget {
  const ProfileCompletionBottomSheet({super.key});

  @override
  State<ProfileCompletionBottomSheet> createState() => _ProfileCompletionBottomSheetState();
}

class _ProfileCompletionBottomSheetState extends State<ProfileCompletionBottomSheet> {

  final TextEditingController nameTextController= TextEditingController();
  final TextEditingController bioTextController= TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 0,
      color: Color(0xff344955),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        height: 56.0,
        child: Row(children: <Widget>[
          IconButton(
            onPressed: (){
              showBarModalBottomSheet(
                  expand: true,
                  context: context,
                  builder: (context)=> Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                      color: Color(0xff232f34),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: const Alignment(0, 0),
                      children: <Widget>[

                        Positioned(
                          top: -36,
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.all(Radius.circular(50)),
                                border: Border.all(
                                    color: Color(0xff232f34), width: 10
                                )
                            ),
                            child: Center(
                              child: ClipOval(
                                child: Image.network(
                                  "lib/assets/user.png",
                                  fit: BoxFit.cover,
                                  height: 36,
                                  width: 36,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                            child: ListView(
                              children: <Widget>[
                                MyTextfield(
                                  hintText: "Name",
                                  obscureText: false,
                                  controller: nameTextController,
                                ),
                                MyTextfield(
                                  hintText: "Bio",
                                  obscureText: false,
                                  controller: bioTextController,
                                )
                              ],
                            )
                        )
                      ],

                    ),
                  )
              );
            },
            icon: Icon(Icons.menu),
            color: Colors.white,
          ),
          Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add),
            color: Colors.white,
          )
        ]),
      ),
    );
  }
}
