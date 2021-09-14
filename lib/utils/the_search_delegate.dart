import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
import 'package:unsplash_row/screens/image_detail_screen.dart';
import 'package:unsplash_row/services/unsplash_api.dart';

class TheSearch extends SearchDelegate<String> {
  UnSplashAPI _unSplashAPI = UnSplashAPI();
  List<UnSplashData> images = [];

  Future<List<UnSplashData>> _load() async {
    Response res = await _unSplashAPI.getSearchResults(query, 1);
    images = res.images;
    return images;
  }

  @override
  String get searchFieldLabel => "Enter something..";

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(),
          );
        if (images.length == 0)
          return Center(
            child: Text("Didn't found anything to show"),
          );
        return StaggeredGridView.countBuilder(
          shrinkWrap: true,
          crossAxisCount: 4,
          itemCount: images.length,
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
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ImageDetail(image: images[index])));
                      },
                      onDoubleTap: () async {
                        /// [Put it at bookmark.]
                        fb.User? user = fb.FirebaseAuth.instance.currentUser;
                        DocumentSnapshot _ds =
                            await FirebaseFirestore.instance.collection('bookmarks').doc(user!.uid).get();
                        UnSplashDataList _data;
                        if (_ds.exists) {
                          _data = UnSplashDataList.fromJson(jsonDecode(jsonEncode(_ds.data())));
                          _data.listUnSplashData?.add(images[index]);
                          log(_data.listUnSplashData.toString());
                          await FirebaseFirestore.instance.collection('bookmarks').doc(user.uid).update(_data.toJson());
                        } else {
                          _data = UnSplashDataList(listUnSplashData: []);
                          _data.listUnSplashData?.add(images[index]);
                          await FirebaseFirestore.instance.collection('bookmarks').doc(user.uid).set(_data.toJson());
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
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty ? ["cook", "book"] : [];
    return Center(
      child: Text("Nothing to show. Try search with some keywords"),
    );
  }
}
