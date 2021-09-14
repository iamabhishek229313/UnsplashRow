import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
import 'package:unsplash_row/screens/image_detail_screen.dart';
import 'package:unsplash_row/services/unsplash_api.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class DiscoverView extends StatefulWidget {
  const DiscoverView({
    Key? key,
    required this.user,
    required this.bookmarkedIds,
  }) : super(key: key);

  final fb.User user;
  final Set<String> bookmarkedIds;

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
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ImageDetail(
                              image: images[index],
                              bookmarkedIds: widget.bookmarkedIds,
                            )));
                  },
                  onDoubleTap: () async {
                    /// [Put it at bookmark if not already is in]
                    _addDocuments(index);
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
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      widget.bookmarkedIds.contains(images[index].id) ? Icons.bookmark : Icons.bookmark_add_outlined,
                      color: Colors.amber.shade600,
                    ),
                    onPressed: () async {
                      if (widget.bookmarkedIds.contains(images[index].id)) {
                        /// [Remove this from bookmarked].
                        DocumentSnapshot _ds =
                            await FirebaseFirestore.instance.collection('bookmarks').doc(widget.user.uid).get();
                        UnSplashDataList _data;
                        _data = UnSplashDataList.fromJson(jsonDecode(jsonEncode(_ds.data())));
                        _data.listUnSplashData!.removeWhere((element) => element.id == images[index].id);
                        widget.bookmarkedIds.remove(images[index].id);
                        await FirebaseFirestore.instance
                            .collection('bookmarks')
                            .doc(widget.user.uid)
                            .update(_data.toJson());
                      } else {
                        _addDocuments(index);
                      }
                    },
                  ),
                )
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

  void _addDocuments(int index) async {
    if (widget.bookmarkedIds.contains(images[index].id)) return;
    DocumentSnapshot _ds = await FirebaseFirestore.instance.collection('bookmarks').doc(widget.user.uid).get();
    UnSplashDataList _data;
    if (_ds.exists) {
      _data = UnSplashDataList.fromJson(jsonDecode(jsonEncode(_ds.data())));
      _data.listUnSplashData?.add(images[index]);
      log(_data.listUnSplashData.toString());
      await FirebaseFirestore.instance.collection('bookmarks').doc(widget.user.uid).update(_data.toJson());
    } else {
      _data = UnSplashDataList(listUnSplashData: []);
      _data.listUnSplashData?.add(images[index]);
      await FirebaseFirestore.instance.collection('bookmarks').doc(widget.user.uid).set(_data.toJson());
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      "Added to Bookmarks",
      style: TextStyle(color: Colors.amber),
    )));
    log("Doc added");
  }
}
