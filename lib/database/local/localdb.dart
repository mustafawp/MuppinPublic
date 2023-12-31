import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:muppin_app/transactions/userdata.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// ignore: camel_case_types
class localDatabase {
  // Veritabanı bağlantısı oluştur
  Future<Database> database() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'user.db');

    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE user(id INTEGER PRIMARY KEY AUTOINCREMENT,docId TEXT,accName TEXT,profilePhoto BLOB,email TEXT,password TEXT,phone TEXT,aboutText TEXT,gender TEXT,birthday TEXT,since TEXT,pronouns TEXT,badges TEXT,instagram TEXT,twitter TEXT,youtube TEXT, discord TEXT)");
      },
      version: 3,
    );
  }

  // Yeni kullanıcı ekle
  Future<void> insertUser(newUser user) async {
    final db = await database();
    await db.insert('user', toMap(user),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Kullanıcıyı güncelle
  Future<void> updateUser(String docId, newUser fields) async {
    final db = await database();
    await db.update(
      'user',
      toMap(fields),
      where: 'docId = ?',
      whereArgs: [docId],
    );
  }

  Future<bool> updateOtherMethod(
      String docId, Map<String, dynamic> fields) async {
    try {
      final db = await database();
      await db.update(
        'user',
        fields,
        where: 'docId = ?',
        whereArgs: [docId],
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("LocalDB Hata: $e");
      }
      return false;
    }
  }

  Future<void> deleteUser(String docId) async {
    final db = await database();
    await db.delete(
      'user',
      where: 'docId = ?',
      whereArgs: [docId],
    );
  }

  Map<String, dynamic> toMap(user) {
    newUser userDatas = user;
    List badgeLists = userDatas.badges;
    String badges = "";
    if (badgeLists.isNotEmpty) {
      for (int badge in badgeLists) {
        badges += "$badge, ";
      }
    }

    String instagram = "", twitter = "", discord = "", youtube = "";
    Map<String, dynamic> map = userDatas.socials;
    if (map.isNotEmpty) {
      if (map["instagram"] is String && map["instagram"] != "") {
        instagram = map["instagram"];
      }
      if (map["twitter"] is String && map["twitter"] != "") {
        twitter = map["twitter"];
      }
      if (map["discord"] is String && map["discord"] != "") {
        discord = map["discord"];
      }
      if (map["youtube"] is String && map["youtube"] != "") {
        youtube = map["youtube"];
      }
    }

    Uint8List profile;
    if (userDatas.profilePhoto is String) {
      profile = Uint8List(0);
    } else {
      profile = userDatas.profilePhoto.bytes;
    }

    return {
      'docId': userDatas.docId,
      'accName': userDatas.accName,
      'profilePhoto': profile,
      'email': userDatas.email,
      'password': userDatas.password,
      'phone': userDatas.phone,
      'aboutText': userDatas.aboutText,
      'gender': userDatas.gender,
      'birthday': userDatas.birthday,
      'since': userDatas.since,
      'pronouns': userDatas.pronouns,
      'badges': badges,
      'instagram': instagram,
      'twitter': twitter,
      'discord': discord,
      'youtube': youtube,
    };
  }

  Future<List> isUserExistsAndGetDatas(String docId) async {
    final db = await database();

    final List<Map<String, dynamic>> result = await db.query(
      'user',
      columns: [
        'docId, accName, aboutText, badges, since,instagram, twitter, discord, youtube, profilePhoto'
      ],
      where: 'docId = ?',
      whereArgs: [docId],
    );

    if (result.isNotEmpty) {
      return [true, result.first];
    } else {
      return [null, null];
    }
  }

  Future<Map<String, dynamic>?> getUserDatas(
      String docId, String columns) async {
    final db = await database();

    final List<Map<String, dynamic>> userData = await db.query(
      'user',
      columns: [columns],
      where: 'docId = ?',
      whereArgs: [docId],
    );

    if (userData.isNotEmpty) {
      return userData.first;
    } else {
      return null;
    }
  }
}
