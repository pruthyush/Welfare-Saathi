import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class LocalizationService extends ChangeNotifier {
  String _currentLanguage = 'ml'; // Default to Malayalam for community accessibility
  Map<String, String> _enStrings = {};
  Map<String, String> _mlStrings = {};

  String get currentLanguage => _currentLanguage;
  bool get isMalayalam => _currentLanguage == 'ml';

  void initWithMaps({
    required Map<String, String> enStrings,
    required Map<String, String> mlStrings,
    String defaultLanguage = 'ml',
  }) {
    _enStrings = enStrings;
    _mlStrings = mlStrings;
    _currentLanguage = defaultLanguage;
    notifyListeners();
  }

  Future<void> loadTranslations() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/terminology.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;

      if (data.containsKey('en')) {
        _enStrings = (data['en'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString()));
      }
      if (data.containsKey('ml')) {
        _mlStrings = (data['ml'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString()));
      }
      notifyListeners();
    } catch (e) {
      // Fallback
    }
  }

  void setLanguage(String langCode) {
    if (_currentLanguage != langCode && (langCode == 'en' || langCode == 'ml')) {
      _currentLanguage = langCode;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _currentLanguage = (_currentLanguage == 'ml') ? 'en' : 'ml';
    notifyListeners();
  }

  String tr(String key) {
    if (isMalayalam) {
      return _mlStrings[key] ?? _enStrings[key] ?? key;
    } else {
      return _enStrings[key] ?? _mlStrings[key] ?? key;
    }
  }
}
