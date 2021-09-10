import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unsplash_row/blocs/theme_bloc.dart';
import 'package:unsplash_row/models/unsplash_data.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageDetail extends StatefulWidget {
  const ImageDetail({Key? key, required this.image}) : super(key: key);
  final UnSplashData image;

  @override
  _ImageDetailState createState() => _ImageDetailState();
}

class _ImageDetailState extends State<ImageDetail> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0.0,
        brightness: Brightness.dark,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        actionsPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            SizedBox(
                              width: 40.0,
                              height: 40.0,
                              child: ClipOval(
                                child: Image.network(widget.image.user?.profileImage?.medium ?? ""),
                              ),
                            ),
                            SizedBox(
                              width: 8.0,
                            ),
                            Text(
                              widget.image.user?.firstName ?? "Unkown",
                              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                            )
                          ],
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Description",
                              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400),
                            ),
                            Text(
                              widget.image.altDescription ?? "",
                              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400),
                            ),
                            SizedBox(
                              height: 16.0,
                            ),
                            Row(children: [
                              Expanded(
                                child: Text(
                                  widget.image.likes.toString() + " likes",
                                  // style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  String? _url = widget.image.urls?.full ?? "";
                                  await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("View at site"),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Icon(Icons.open_in_new)
                                  ],
                                ),
                              )
                            ])
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'OK'),
                            child: const Text('OK'),
                          ),
                        ],
                      ));
            },
            mini: true,
            child: Icon(
              Icons.arrow_upward_outlined,
              color: Colors.black,
            ),
          ),
          SizedBox(
            height: 8.0,
          ),
          Text(
            "More details",
            style: TextStyle(fontSize: 12.0, color: Colors.white),
          )
        ],
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: InteractiveViewer(
          panEnabled: false, // Set it to false
          boundaryMargin: EdgeInsets.zero,
          minScale: 0.1,
          maxScale: 2,
          scaleEnabled: true,
          child: CachedNetworkImage(
            imageUrl: widget.image.urls?.full ?? "",
            fit: BoxFit.cover,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}


          // Align(
          //     alignment: Alignment.bottomCenter,
          //     child: Container(
          //       height: 100.0,
          //       width: double.maxFinite,
          //       margin: EdgeInsets.all(8.0).copyWith(bottom: 36.0),
          //       color: (BlocProvider.of<ThemeBloc>(context).state.themeMode == ThemeMode.dark)
          //           ? Colors.black38
          //           : Colors.white70,
          //       child: Row(
          //         children: [
          //           Text(
          //             "by ",
          //             style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
          //           ),
          //           Text(
          //             widget.image.user?.username ?? "Unknown",
          //             style: TextStyle(fontSize: 18.0, color: Colors.indigo.shade500, fontWeight: FontWeight.w600),
          //           )
          //         ],
          //       ),
          //     ))
