import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
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
                    // text: 'Discover',
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
  _load() async {
    Response res = await _unSplashAPI.getImages(0);
    images = res.images;
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        return StaggeredGridView.countBuilder(
          crossAxisCount: 4,
          itemCount: images.length,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
          itemBuilder: (BuildContext context, int index) => Card(
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
                    onDoubleTap: () {
                      /// [Put it at bookmark.]
                    },
                    child: Container(
                      constraints: BoxConstraints.expand(),
                      child: CachedNetworkImage(
                        imageUrl: images[index].urls?.regular ?? "",
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, downloadProgress) =>
                            CircularProgressIndicator(value: downloadProgress.progress),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                  // Align(
                  //   alignment: Alignment.bottomRight,
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.end,
                  //     children: [
                  //       Text(images[index].likes.toString(),
                  //           style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700, color: Colors.white70)),
                  //       Icon(
                  //         Icons.favorite,
                  //         color: Colors.pink,
                  //         size: 14.0,
                  //       )
                  //     ],
                  //   ),
                  // )
                ],
              ),
            ),
          ),
          staggeredTileBuilder: (int index) => new StaggeredTile.count(2, index.isEven ? 2 : 3),
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 0.0,
        );
      },
    );
  }
}
