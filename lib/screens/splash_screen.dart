import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:unsplash_row/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _jumpToScreen();
  }

  _jumpToScreen() {
    Timer(Duration(milliseconds: 800),
        () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Text("UnsplashRow", style: TextStyle(fontSize: 42.0, color: Colors.indigo)));
  }
}
