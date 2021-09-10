import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unsplash_row/screens/authentication_screen.dart';
import 'package:unsplash_row/screens/home_screen.dart';

class StateWrapperScreen extends StatefulWidget {
  const StateWrapperScreen({Key? key}) : super(key: key);

  @override
  _StateWrapperScreenState createState() => _StateWrapperScreenState();
}

class _StateWrapperScreenState extends State<StateWrapperScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          print("Snapshot Data is : " + snapshot.data.toString());
          if (snapshot.hasData) {
            if (snapshot.data == null)
              return AuthenticationScreen();
            else
              return HomeScreen();
          }
          return AuthenticationScreen();
        });
  }
}
