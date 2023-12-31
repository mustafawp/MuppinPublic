import 'package:shared_preferences/shared_preferences.dart';

class Shareds {
  static Future<bool> sharedEkleGuncelle(String key, String value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      preferences.setString(key, value);
      return true;
    } catch (error) {
      return false;
    }
  }

  static Future<String> sharedCek(String Key) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      String? value = preferences.getString(Key).toString();
      if (value.isNotEmpty || value != "") {
        return value;
      } else {
        return "Değer Bulunamadı";
      }
    } catch (error) {
      return "Değer Bulunamadı";
    }
  }

  static Future<bool> sharedSil(String Key) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      preferences.remove(Key);
      return true;
    } catch (error) {
      return false;
    }
  }
}
