import 'dart:convert';
import 'dart:developer';

import 'package:unsplash_row/models/search_results_model.dart' as sr;
import 'package:unsplash_row/models/unsplash_data.dart';

import 'package:http/http.dart' as http;

class UnSplashAPI {
  late String location;
  late String endPoint_photos;
  late String endPoint_search;
  late String ACCESS_KEY;
  late String SECRET_KEY;
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
    log("Hit at : " + url.toString());
    var headers = {"Authorization": "Client-ID " + ACCESS_KEY};
    http.Response _response = await http.get(url, headers: headers);
    if (_response.statusCode == 200) {
      sr.SearchResult _searchResult = sr.SearchResult.fromJson(jsonDecode(_response.body));
      log("SR RESULT : " + _searchResult.toJson().toString());

      for (int currentIndex = 0; currentIndex < _searchResult.results!.length; currentIndex++) {
        UnSplashData _unSplashData = UnSplashData();
        _unSplashData.id = _searchResult.results![currentIndex].id;
        _unSplashData.altDescription = _searchResult.results![currentIndex].description;
        _unSplashData.createdAt = _searchResult.results![currentIndex].publishedAt;
        _unSplashData.description = _searchResult.results![currentIndex].description;
        _unSplashData.likedByUser = _searchResult.results![currentIndex].coverPhoto!.likedByUser;
        _unSplashData.likes = _searchResult.results![currentIndex].coverPhoto!.likes;
        _unSplashData.updatedAt = _searchResult.results![currentIndex].updatedAt;
        _unSplashData.urls = Urls(
            full: _searchResult.results![currentIndex].coverPhoto!.urls!.full,
            raw: _searchResult.results![currentIndex].coverPhoto!.urls!.raw,
            regular: _searchResult.results![currentIndex].coverPhoto!.urls!.regular,
            small: _searchResult.results![currentIndex].coverPhoto!.urls!.small,
            thumb: _searchResult.results![currentIndex].coverPhoto!.urls!.small);
        _unSplashData.user = User(
            firstName: _searchResult.results![currentIndex].user!.firstName,
            id: _searchResult.results![currentIndex].user!.id,
            profileImage: ProfileImage(
              large: _searchResult.results![currentIndex].user!.profileImage!.large,
              medium: _searchResult.results![currentIndex].user!.profileImage!.medium,
              small: _searchResult.results![currentIndex].user!.profileImage!.small,
            ),
            name: _searchResult.results![currentIndex].user!.name,
            totalLikes: _searchResult.results![currentIndex].user!.totalLikes,
            username: _searchResult.results![currentIndex].user!.username,
            updatedAt: _searchResult.results![currentIndex].user!.updatedAt,
            lastName: _searchResult.results![currentIndex].user!.lastName);

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
