import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
import 'package:unsplash_row/screens/home/bookmarks_tab.dart';
import 'package:unsplash_row/screens/home/discover_tab.dart';
import 'package:unsplash_row/utils/constants.dart';
import 'package:unsplash_row/utils/network_error_dialog.dart';
import 'package:unsplash_row/utils/the_search_delegate.dart';
import 'dart:convert';
import 'package:showcaseview/showcaseview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Set<String> hashSet = {};

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> _showSearch() async {
    await showSearch(
      context: context,
      delegate: TheSearch(hashSet),
      query: "",
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
      return;
    }
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  GlobalKey _one = GlobalKey();
  GlobalKey _two = GlobalKey();
  GlobalKey _three = GlobalKey();
  GlobalKey _four = GlobalKey();

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _tabController = TabController(length: 2, vsync: this);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkFirtTime();
  }

  _checkFirtTime() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    bool? firstTime = _prefs.getBool(AppConstants.firstTime);
    if (firstTime == null || firstTime == true) {
      WidgetsBinding.instance!
          .addPostFrameCallback((_) => ShowCaseWidget.of(context)!.startShowCase([_one, _two, _three, _four]));
      _prefs.setBool(AppConstants.firstTime, false);
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
      if (_connectionStatus.index == 3) {
        showNetworkErrorDailog(context);
      }
      log(_connectionStatus.index.toString() + " : " + _connectionStatus.toString());
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<fb.User?> _getUser() async {
    fb.User? _user = fb.FirebaseAuth.instance.currentUser;
    return _user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Showcase(
                  key: _four,
                  title: "Hello Buddy!",
                  description:
                      "These are the quick lessons for you\n1. Tap on an image view full-image.\n2. Double-Tap to add an image into bookmark\n3. Tap on the Add/Remove bookmark icon to do other operations.",
                  descTextStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                  child: Text("UnsplashRow")),
              pinned: true,
              floating: true,
              elevation: 10.0,
              actions: [
                Showcase(
                  key: _one,
                  titleTextStyle: TextStyle(fontSize: 14.0, color: Colors.black),
                  descTextStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                  title: "Toggle Buttons",
                  description: "Click here to logout, Toggle dark and light theme & search",
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () async {
                            await fb.FirebaseAuth.instance.signOut();
                          },
                          icon: Icon(Icons.login_outlined)),
                      IconButton(
                          onPressed: () {
                            BlocProvider.of<ThemeBloc>(context).add(ThemeChanged(
                                (BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark) == false));
                          },
                          icon: Icon(BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined)),
                      IconButton(
                          onPressed: () {
                            _showSearch();
                          },
                          icon: Icon(Icons.search_rounded))
                    ],
                  ),
                )
              ],
              bottom: TabBar(
                tabs: <Tab>[
                  Tab(
                    icon: Showcase(
                      key: _two,
                      titleTextStyle: TextStyle(fontSize: 14.0, color: Colors.black),
                      descTextStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                      title: "Discover Images",
                      description: "Tap here to discover fresh images",
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.public_outlined),
                          SizedBox(
                            width: 8.0,
                          ),
                          Text("Discover"),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    icon: Showcase(
                      key: _three,
                      titleTextStyle: TextStyle(fontSize: 14.0, color: Colors.black),
                      descTextStyle: TextStyle(fontSize: 12.0, color: Colors.black),
                      title: "Bookmarked Images",
                      description: "Tap here to see your bookmarked images",
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_outlined),
                          SizedBox(
                            width: 8.0,
                          ),
                          Text("Bookmarks"),
                        ],
                      ),
                    ),
                  ),
                ],
                controller: _tabController,
              ),
            ),
          ];
        },
        body: FutureBuilder(
          future: _getUser(),
          builder: (BuildContext context, AsyncSnapshot user) {
            if (!user.hasData)
              return Center(
                child: CircularProgressIndicator(),
              );
            return StreamBuilder(
              stream: FirebaseFirestore.instance.collection('bookmarks').doc(user.data!.uid).snapshots(),
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                if (!snapshot.hasData)
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                hashSet = {};
                if (snapshot.data?.data() != null) {
                  UnSplashDataList? images = UnSplashDataList.fromJson(jsonDecode(jsonEncode(snapshot.data!.data())));
                  for (int i = 0; i < images.listUnSplashData!.length; i++) {
                    hashSet.add(images.listUnSplashData![i].id ?? "");
                  }
                }
                return TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    DiscoverView(
                      user: user.data,
                      bookmarkedIds: hashSet,
                    ),
                    BookmarksView(
                      user: user.data,
                      bookmarkedIds: hashSet,
                      documentSnapshot: snapshot.data,
                    )
                    // Container(color: Colors.indigo),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
