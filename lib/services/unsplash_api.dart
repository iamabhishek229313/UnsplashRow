import 'dart:convert';

import 'package:unsplash_row/models/unsplash_data.dart';

import 'package:http/http.dart' as http;

class UnSplashAPI {
  late String location;
  late String endPoint;
  late String ACCESS_KEY;
  late String SECRET_KEY;
  UnSplashAPI() {
    location = 'https://api.unsplash.com/';
    endPoint = 'photos/';
    ACCESS_KEY = 'Nk-lHXLHAklq5jt1Kilec5z_OazU9irbMGVUNNJEzwU';
    SECRET_KEY = 'Q6A4ypm3BZ4NAiKzeTtyWhBLwaps_gjQXF95uEzxwBQ';
  }
  Future<Response> getImages(int page) async {
    List<UnSplashData> images = [];
    var url = Uri.parse(location + endPoint + "?page=" + page.toString());
    var headers = {"Authorization": "Client-ID " + ACCESS_KEY};
    http.Response _response = await http.get(url, headers: headers);
    if (_response.statusCode == 200) {
      images = (jsonDecode(_response.body) as List).map((element) => UnSplashData.fromJson(element)).toList();
      return Response(true, images);
    }
    return Response(false, images);
  }
}

class Response {
  Response(this.valid, this.images);
  final bool valid;
  final List<UnSplashData> images;
}
