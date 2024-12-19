import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void displayErrorMessage(String msg, BuildContext context){
  showDialog(context: context, builder: (context)=> AlertDialog(
    title: Text(msg),
  ));
}