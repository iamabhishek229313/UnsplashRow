import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:localstorage/localstorage.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
import 'package:unsplash_row/screens/image_detail_screen.dart';
import 'package:unsplash_row/services/unsplash_api.dart';
import 'package:unsplash_row/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                    onPressed: () {
                      BlocProvider.of<ThemeBloc>(context).add(ThemeChanged(
                          (BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark) == false));
                    },
                    icon: Icon(BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined)),
                IconButton(onPressed: () {}, icon: Icon(Icons.search_rounded))
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
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            DiscoverView(),
            DiscoverView()
            // Container(color: Colors.indigo),
          ],
        ),
      ),
    );
  }
}

class DiscoverView extends StatefulWidget {
  const DiscoverView({
    Key? key,
  }) : super(key: key);

  @override
  _DiscoverViewState createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
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
                  onDoubleTap: () {
                    /// [Put it at bookmark.]
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
}

class BookmarksView extends StatefulWidget {
  const BookmarksView({Key? key}) : super(key: key);

  @override
  _BookmarksViewState createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  final LocalStorage storage = new LocalStorage('storage');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: storage.ready,
      builder: (BuildContext context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        Map<String, UnSplashData> data = storage.getItem('bookmarks');

        return StaggeredGridView.countBuilder(
          shrinkWrap: true,
          crossAxisCount: 4,
          itemCount: data.length,
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
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ImageDetail(image: images[index])));
                      },
                      onDoubleTap: () {
                        /// [Put it at bookmark.]
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
      },
    );

    if (images.isEmpty)
      return Center(
        child: CircularProgressIndicator(),
      );
  }
}
