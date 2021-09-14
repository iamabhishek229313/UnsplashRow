import 'package:unsplash_row/models/search_results_model.dart' as sr;
import 'package:unsplash_row/models/unsplash_data.dart';

UnSplashData parseResults(sr.SearchResult _searchResult, int currentIndex) {
  UnSplashData _unSplashData = UnSplashData();
  _unSplashData.id = _searchResult.results![currentIndex].id;
  _unSplashData.altDescription = _searchResult.results![currentIndex].description;
  _unSplashData.createdAt = _searchResult.results![currentIndex].publishedAt;
  _unSplashData.description = _searchResult.results![currentIndex].description;
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

  return _unSplashData;
}
