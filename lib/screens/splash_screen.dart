import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/screens/state_wrapper_screen.dart';
import 'package:unsplash_row/utils/constants.dart';

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
    Timer(Duration(milliseconds: 320),
        () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StateWrapperScreen())));
  }

  @override
  Widget build(BuildContext context) {
    bool is_dark = (BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark);

    return Scaffold(
        backgroundColor: is_dark ? AppColors.black : Colors.white,
        body: Center(
            child: Text("UnsplashRow",
                style: TextStyle(fontSize: 54.0, color: Colors.indigo.shade300, fontWeight: FontWeight.w700))));
  }
}
