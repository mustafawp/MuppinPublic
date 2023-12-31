import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:muppin_app/transactions/userdata.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// ignore: camel_case_types
class localRecents {
  Future<Database> database() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recents.db');

    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE recents (docId TEXT PRIMARY KEY, accName TEXT, profilePhoto BLOB, aboutText TEXT)");
      },
      version: 1,
    );
  }

  // Yeni kullanıcı ekle
  Future<void> insertUser(searchUserDatas user) async {
    final db = await database();
    await db.insert('recents', toMap(user),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(String docId, searchUserDatas fields) async {
    final db = await database();
    await db.update(
      'recents',
      toMap(fields),
      where: 'docId = ?',
      whereArgs: [docId],
    );
  }

  Future<void> deleteUser(String docId) async {
    final db = await database();
    await db.delete(
      'recents',
      where: 'docId = ?',
      whereArgs: [docId],
    );
  }

  Map<String, dynamic> toMap(user) {
    searchUserDatas userDatas = user;

    Uint8List profile;
    if (userDatas.pp is String) {
      profile = Uint8List(0);
    } else {
      profile = userDatas.pp.bytes;
    }

    return {
      'docId': userDatas.documentId,
      'accName': userDatas.username,
      'profilePhoto': profile,
      'aboutText': userDatas.about,
    };
  }

  Future<List<searchUserDatas>?> getAllRecents() async {
    try {
      final db = await database();
      final List<Map<String, dynamic>> userData = await db.query(
        'recents',
        columns: ['docId, accName, profilePhoto, aboutText'],
        limit: 20,
      );

      List<searchUserDatas> userList = [];

      for (Map<String, dynamic> data in userData) {
        dynamic profile;
        if (data["profilePhoto"].isNotEmpty) {
          profile = Blob(data["profilePhoto"]);
        } else {
          profile = "-";
        }
        userList.add(searchUserDatas(
          username: data['accName'],
          pp: profile,
          documentId: data['docId'],
          about: data['aboutText'],
        ));
      }

      if (userList.isNotEmpty) {
        return userList;
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("localRecent | Error: $e");
      }
      return [];
    }
  }
}
