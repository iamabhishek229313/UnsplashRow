import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:unsplash_row/screens/image_detail_screen.dart';

class BookmarksView extends StatefulWidget {
  const BookmarksView({Key? key, required this.user, required this.documentSnapshot, required this.bookmarkedIds})
      : super(key: key);

  final fb.User user;
  final DocumentSnapshot<Map<String, dynamic>>? documentSnapshot;
  final Set<String> bookmarkedIds;

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
    log(widget.documentSnapshot!.data().toString());
    if (widget.documentSnapshot!.data() == null)
      return Center(
        child: Text("Didn't found anything Bookmarked."),
      );
    UnSplashDataList? images = UnSplashDataList.fromJson(jsonDecode(jsonEncode(widget.documentSnapshot!.data())));
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
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ImageDetail(
                              image: images.listUnSplashData![index],
                              bookmarkedIds: widget.bookmarkedIds,
                            )));
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
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      widget.bookmarkedIds.contains(images.listUnSplashData![index].id)
                          ? Icons.bookmark
                          : Icons.bookmark_add_outlined,
                      color: Colors.amber.shade600,
                    ),
                    onPressed: () async {
                      if (widget.bookmarkedIds.contains(images.listUnSplashData![index].id)) {
                        /// [Remove this from bookmarked].
                        DocumentSnapshot _ds =
                            await FirebaseFirestore.instance.collection('bookmarks').doc(widget.user.uid).get();
                        UnSplashDataList _data;
                        _data = UnSplashDataList.fromJson(jsonDecode(jsonEncode(_ds.data())));
                        _data.listUnSplashData!
                            .removeWhere((element) => element.id == images.listUnSplashData![index].id);
                        widget.bookmarkedIds.remove(images.listUnSplashData![index].id);
                        await FirebaseFirestore.instance
                            .collection('bookmarks')
                            .doc(widget.user.uid)
                            .update(_data.toJson());
                      } else {}
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
      staggeredTileBuilder: (int index) => StaggeredTile.count(2, index.isEven ? 2 : 3),
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 0.0,
    );
  }
}
