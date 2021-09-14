import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/screens/splash_screen.dart';
import 'package:unsplash_row/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(BlocProvider(
    create: (_) => new ThemeBloc(ThemeState(ThemeMode.dark))..add(ThemeLoadStarted()),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Current Affairs Section',
          themeMode: themeState.themeMode,
          theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Colors.white,
              backgroundColor: Colors.white,
              textTheme: GoogleFonts.robotoTextTheme()),
          darkTheme:
              ThemeData(brightness: Brightness.dark, primaryColor: AppColors.black, backgroundColor: AppColors.black),
          home: SplashScreen(),
        );
      },
    );
  }
}
