import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
import 'package:unsplash_row/screens/image_detail_screen.dart';
import 'package:unsplash_row/services/unsplash_api.dart';
import 'package:unsplash_row/utils/constants.dart';
import 'package:unsplash_row/utils/the_search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> _showSearch() async {
    await showSearch(
      context: context,
      delegate: TheSearch(),
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

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _tabController = TabController(length: 2, vsync: this);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
      if (_connectionStatus.index == 3) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Connectivity Issue"), Icon(Icons.wifi_off_outlined)],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Once you have stronger internet connection, we'll automatically show you stuffs.",
                    style: TextStyle(fontSize: 14.0)),
                SizedBox(
                  height: 16.0,
                ),
                SizedBox(
                  width: double.maxFinite,
                  child: RaisedButton(
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      child: Text(
                        "Close this Application",
                        style: TextStyle(color: Colors.white),
                      ),
                      color: AppColors.black,
                      elevation: 10.0),
                )
              ],
            ),
          ),
        );
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
              title: Text("UnsplashRow"),
              pinned: true,
              floating: true,
              elevation: 10.0,
              actions: [
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
              bottom: TabBar(
                tabs: <Tab>[
                  Tab(
                    icon: Row(
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
                  Tab(
                    icon: Row(
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
                ],
                controller: _tabController,
              ),
            ),
          ];
        },
        body: FutureBuilder(
          future: _getUser(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData)
              return Center(
                child: CircularProgressIndicator(),
              );
            return TabBarView(
              controller: _tabController,
              children: <Widget>[
                DiscoverView(
                  user: snapshot.data,
                ),
                BookmarksView(
                  user: snapshot.data,
                )
                // Container(color: Colors.indigo),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DiscoverView extends StatefulWidget {
  const DiscoverView({
    Key? key,
    required this.user,
  }) : super(key: key);

  final fb.User? user;

  @override
  _DiscoverViewState createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> with AutomaticKeepAliveClientMixin<DiscoverView> {
  UnSplashAPI _unSplashAPI = UnSplashAPI();
  List<UnSplashData> images = [];

  static int page = 1;
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (_isLoading == false) {
          _load();
        }
      }
    });
  }

  @override
  void dispose() {
    if (mounted) _scrollController.dispose();
    super.dispose();
  }

  Future _load() async {
    if (_isLoading == false && mounted) {
      setState(() {
        _isLoading = true;
      });
      Response res = await _unSplashAPI.getImages(page);
      if (mounted)
        setState(() {
          images.addAll(res.images);
          _isLoading = false;
          page++;
        });
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty)
      return Center(
        child: CircularProgressIndicator(),
      );
    return StaggeredGridView.countBuilder(
      shrinkWrap: true,
      controller: _scrollController,
      crossAxisCount: 4,
      itemCount: images.length + 1,
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
      itemBuilder: (BuildContext context, int index) {
        if (index == images.length)
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(
                height: 8.0,
              ),
              Text(
                "Loading more...",
                style: TextStyle(fontSize: 14.0),
              )
            ],
          );
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          elevation: 2,
          borderOnForeground: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.0),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageDetail(image: images[index])));
                  },
                  onDoubleTap: () async {
                    /// [Put it at bookmark.]
                    DocumentSnapshot _ds =
                        await FirebaseFirestore.instance.collection('bookmarks').doc(widget.user!.uid).get();
                    UnSplashDataList _data;
                    if (_ds.exists) {
                      _data = UnSplashDataList.fromJson(jsonDecode(jsonEncode(_ds.data())));
                      _data.listUnSplashData?.add(images[index]);
                      log(_data.listUnSplashData.toString());
                      await FirebaseFirestore.instance
                          .collection('bookmarks')
                          .doc(widget.user!.uid)
                          .update(_data.toJson());
                    } else {
                      _data = UnSplashDataList(listUnSplashData: []);
                      _data.listUnSplashData?.add(images[index]);
                      await FirebaseFirestore.instance
                          .collection('bookmarks')
                          .doc(widget.user!.uid)
                          .set(_data.toJson());
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                      "Added to Bookmarks",
                      style: TextStyle(color: Colors.amber),
                    )));
                    log("Doc added");
                  },
                  child: Container(
                    constraints: BoxConstraints.expand(),
                    child: CachedNetworkImage(
                      imageUrl: images[index].urls?.regular ?? "",
                      fit: BoxFit.cover,
                      progressIndicatorBuilder: (context, url, downloadProgress) =>
                          Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      staggeredTileBuilder: (int index) => new StaggeredTile.count(2, index.isEven ? 2 : 3),
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 0.0,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class BookmarksView extends StatefulWidget {
  const BookmarksView({Key? key, required this.user}) : super(key: key);

  final fb.User? user;

  @override
  _BookmarksViewState createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('bookmarks').doc(widget.user!.uid).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(),
          );
        log(snapshot.data!.data().toString());
        if (snapshot.data!.data() == null)
          return Center(
            child: Text("Didn't found anything Bookmarked."),
          );
        UnSplashDataList? images = UnSplashDataList.fromJson(jsonDecode(jsonEncode(snapshot.data!.data())));
        if (images == null || images.listUnSplashData!.length == 0)
          return Center(
            child: Text("Didn't found anything Bookmarked."),
          );

        return StaggeredGridView.countBuilder(
          shrinkWrap: true,
          crossAxisCount: 4,
          itemCount: images.listUnSplashData!.length,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
          itemBuilder: (BuildContext context, int index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
              elevation: 2,
              borderOnForeground: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7.0),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ImageDetail(image: images.listUnSplashData![index])));
                      },
                      onDoubleTap: () {
                        /// [Put it at bookmark.]
                      },
                      child: Container(
                        constraints: BoxConstraints.expand(),
                        child: CachedNetworkImage(
                          imageUrl: images.listUnSplashData![index].urls?.regular ?? "",
                          fit: BoxFit.cover,
                          progressIndicatorBuilder: (context, url, downloadProgress) =>
                              Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          staggeredTileBuilder: (int index) => StaggeredTile.count(2, index.isEven ? 2 : 3),
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 0.0,
        );
      },
    );
  }
}
