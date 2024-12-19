import 'package:flutter/material.dart';

ThemeData darkMode=ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
        surface: Colors.grey.shade900,
        primary: Colors.grey.shade700,
        secondary: Colors.grey.shade500,
        inversePrimary: Colors.grey.shade200,
        tertiary: Colors.blue[300]
    ),
    textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.grey.shade200,
        displayColor: Colors.white
    )
);