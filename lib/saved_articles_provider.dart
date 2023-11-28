import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedArticlesProvider extends ChangeNotifier {
  final List<String> _savedArticles = [];

  SavedArticlesProvider() {
    _loadSavedArticles();
  }

  List<String> get savedArticles => _savedArticles;

  Future<void> _loadSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_articles') ?? [];
    _savedArticles.addAll(saved);
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('saved_articles', _savedArticles);
  }

  void addArticle(String articleUrl) {
    _savedArticles.add(articleUrl);
    _saveToPrefs();
    notifyListeners();
  }

  void removeArticle(String articleUrl) {
    _savedArticles.remove(articleUrl);
    _saveToPrefs();
    notifyListeners();
  }

  bool isArticleSaved(String url) {
    return _savedArticles.contains(url);
  }
}
