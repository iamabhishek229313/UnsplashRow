import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/utils/constants.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("Weclome to UnSplashRow",
                style: TextStyle(fontSize: 42.0, color: Colors.indigo.shade300, fontWeight: FontWeight.bold)),
            Text("Let's get started with a quick Authentication.", style: TextStyle(fontSize: 28.0)),
            SizedBox(
              height: screenHeight * 0.065,
              width: double.maxFinite,
              child: RaisedButton(
                elevation: 10,
                onPressed: () async {
                  UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0)),
                color: BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark
                    ? Colors.white
                    : AppColors.black,
                child: Text(
                  "Get started",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark
                          ? Colors.black
                          : Colors.white,
                      fontSize: 24.0),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
