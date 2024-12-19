import 'package:flutter/cupertino.dart';
import 'package:socialapp/pages/login_page.dart';
import 'package:socialapp/pages/signup_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLoginPage = true;

  void toggleScreen() {
    setState(() {
      showLoginPage=!showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
   if(showLoginPage) return LoginPage(onTap: toggleScreen);
   else return SignupPage(onTap: toggleScreen);
  }
}
