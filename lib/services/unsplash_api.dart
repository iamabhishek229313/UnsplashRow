import 'dart:convert';
import 'dart:developer';

import 'package:unsplash_row/models/search_results_model.dart' as sr;
import 'package:unsplash_row/models/unsplash_data.dart';

import 'package:http/http.dart' as http;
import 'package:unsplash_row/utils/parse_search_data.dart';

class UnSplashAPI {
  static late String location;
  static late String endPoint_photos;
  static late String endPoint_search;
  static late String ACCESS_KEY;
  static late String SECRET_KEY;
  UnSplashAPI() {
    location = 'https://api.unsplash.com/';
    endPoint_photos = 'photos/';
    endPoint_search = 'search/';
    ACCESS_KEY = 'Nk-lHXLHAklq5jt1Kilec5z_OazU9irbMGVUNNJEzwU';
    SECRET_KEY = 'Q6A4ypm3BZ4NAiKzeTtyWhBLwaps_gjQXF95uEzxwBQ';
  }
  Future<Response> getImages(int page) async {
    List<UnSplashData> images = [];
    var url = Uri.parse(location + endPoint_photos + "?page=" + page.toString());
    var headers = {"Authorization": "Client-ID " + ACCESS_KEY};
    http.Response _response = await http.get(url, headers: headers);
    if (_response.statusCode == 200) {
      images = (jsonDecode(_response.body) as List).map((element) => UnSplashData.fromJson(element)).toList();
      return Response(true, images);
    }
    return Response(false, images);
  }

  Future<Response> getSearchResults(String keyword, int page) async {
    List<UnSplashData> images = [];
    var url = Uri.parse(location + endPoint_search + "collections?page=" + page.toString() + "&query=" + keyword);
    var headers = {"Authorization": "Client-ID " + ACCESS_KEY};
    http.Response _response = await http.get(url, headers: headers);
    if (_response.statusCode == 200) {
      sr.SearchResult _searchResult = sr.SearchResult.fromJson(jsonDecode(_response.body));
      for (int currentIndex = 0; currentIndex < _searchResult.results!.length; currentIndex++) {
        UnSplashData _unSplashData = parseResults(_searchResult, currentIndex);
        images.add(_unSplashData);
      }
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
