import 'package:flutter/foundation.dart';

class DataProvider with ChangeNotifier {
  String followersCount = "0";
  String followingCount = "0";

  DataProvider._privateConstructor();
  static final DataProvider _instance = DataProvider._privateConstructor();

  factory DataProvider() {
    return _instance;
  }
}
