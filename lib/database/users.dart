import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:muppin_app/database/local/localdb.dart';
import 'package:muppin_app/transactions/shareds.dart';
import 'package:muppin_app/transactions/userdata.dart';

// ignore: camel_case_types
class database {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Users');

  Future<bool> addUser(Map<String, dynamic> fields) async {
    try {
      String newDocumentId = usersCollection.doc().id;
      await usersCollection.doc(newDocumentId).set({
        'documentId': newDocumentId,
        ...fields,
      });
      newUser user = newUser(
          docId: newDocumentId,
          accName: fields["username"],
          profilePhoto: fields["pp"],
          email: fields["email"],
          password: fields["password"],
          phone: fields["phone"],
          aboutText: fields["about"],
          gender: fields["gender"],
          birthday: fields["birthday"],
          since: fields["joined"],
          pronouns: fields["pronouns"],
          badges: fields["badges"],
          socials: fields["socials"]);
      localDatabase db = localDatabase();
      await db.insertUser(user);
      await Shareds.sharedEkleGuncelle("docId", newDocumentId);
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Hata: $error');
      }
      return false;
    }
  }

  Future<bool> deleteUser(String documentId) async {
    try {
      await usersCollection.doc(documentId).delete();
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Hata: $error');
      }
      return false;
    }
  }

  Future<bool> updateUser(
      String username, String newName, String newEmail) async {
    try {
      await usersCollection.doc(username).update({
        'name': newName,
        'email': newEmail,
      });
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Hata: $error');
      }
      return false;
    }
  }

  Future<bool> getUsersByField(String fieldName, dynamic fieldValue) async {
    try {
      QuerySnapshot querySnapshot =
          await usersCollection.where(fieldName, isEqualTo: fieldValue).get();

      if (querySnapshot.size > 0) {
        /*for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
            print('Kullanıcı adı: ${documentSnapshot['username']}');   Veri böyle çekiliyor örnek
        } */
        return true;
      } else {
        return false;
      }
    } catch (error) {
      if (kDebugMode) {
        print('Hata: $error');
      }
      return false;
    }
  }

  Future<String> logInControl(String accName, String accPassword) async {
    try {
      QuerySnapshot querySnapshot =
          await usersCollection.where("username", isEqualTo: accName).get();

      if (querySnapshot.docs.isEmpty) {
        querySnapshot =
            await usersCollection.where("email", isEqualTo: accName).get();
      }

      if (querySnapshot.size > 0) {
        for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
          String password = documentSnapshot['password'].toString();
          if (password == accPassword) {
            localDatabase db = localDatabase();
            List state = await db
                .isUserExistsAndGetDatas(documentSnapshot['documentId']);
            newUser user = newUser(
              docId: documentSnapshot['documentId'].toString(),
              accName: documentSnapshot["username"].toString(),
              profilePhoto: documentSnapshot["pp"],
              email: documentSnapshot["email"].toString(),
              password: documentSnapshot["password"].toString(),
              phone: documentSnapshot["phone"].toString(),
              aboutText: documentSnapshot["about"].toString(),
              gender: documentSnapshot["gender"].toString(),
              birthday: documentSnapshot["birthday"].toString(),
              since: documentSnapshot["joined"].toString(),
              pronouns: documentSnapshot["pronouns"].toString(),
              badges: documentSnapshot['badges'],
              socials: documentSnapshot["socials"],
            );
            if (state[0] == null || !(state[0])) {
              localDatabase db = localDatabase();
              await db.insertUser(user);
            } else if (state[0]) {
              await db.updateUser(documentSnapshot['documentId'], user);
            }
            await Shareds.sharedEkleGuncelle(
                "docId", documentSnapshot['documentId']);
            return "dogrulandi";
          } else {
            return "Şifre Hatalı! Lütfen tekrar deneyin.";
          }
        }
        return "Bilinmeyen bir hata oluştu, daha sonra tekrar dene. D1";
      } else {
        return "Böyle bir kullanıcı adına sahip hesap bulunamadı.";
      }
    } catch (error) {
      if (kDebugMode) {
        print('Hata: $error');
      }
      return "Bilinmeyen bir hata oluştu, daha sonra tekrar dene. D2";
    }
  }

  Future<UserData> getUserDatasFromFieldName(
    List<String> gevraagdeGegevens,
    String index,
    String whoindex,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await usersCollection.where(whoindex, isEqualTo: index).get();
      if (querySnapshot.size > 0) {
        List<dynamic> redatas = [];
        for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
          for (int i = 0; i < gevraagdeGegevens.length; i++) {
            final fieldValue = documentSnapshot[gevraagdeGegevens[i]];
            final value = fieldValue ?? "";
            redatas.add(value);
          }
        }
        return UserData(true, redatas);
      } else {
        final emptyData = List.filled(gevraagdeGegevens.length, "");
        return UserData(false, emptyData);
      }
    } catch (error) {
      if (kDebugMode) {
        print('! ? Hata: $error');
      }
      return UserData(false, "error");
    }
  }

  Future<bool> updateDatas(Map datas, String key) async {
    try {
      await usersCollection.doc(key).update(datas as Map<Object, Object?>);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Users | updateDatas | Hata: $e");
      }
      return false;
    }
  }

  Future<List<DocumentSnapshot>> getRandomData(int count) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Users').get();
    List<DocumentSnapshot> documents = snapshot.docs;

    if (count > documents.length) {
      count = documents.length;
    }

    documents.shuffle();

    return documents.sublist(0, count);
  }

  Future<Map<String, List>> getRandomUsernames() async {
    try {
      String userDocId = await Shareds.sharedCek("docId");

      List<DocumentSnapshot> randomData = await getRandomData(12);
      if (randomData.isNotEmpty) {
        Map<String, List> usernameMap = {};
        Set<String> addedUsernames = {};

        for (DocumentSnapshot snapshot in randomData) {
          String username = snapshot['username'];

          if (!addedUsernames.contains(username) &&
              snapshot['documentId'] != userDocId) {
            addedUsernames.add(username);

            String bio = snapshot['about'];
            String documentId = snapshot['documentId'];

            if (snapshot['pp'].runtimeType == String) {
              String profile = snapshot['pp'];
              usernameMap[username] = [documentId, bio, profile];
            } else {
              Blob profile = snapshot['pp'];
              usernameMap[username] = [documentId, bio, profile];
            }
          } else {
            List<DocumentSnapshot> randomData2 = await getRandomData(1);
            for (DocumentSnapshot ss in randomData2) {
              String otherUser = ss['username'];
              if (!addedUsernames.contains(otherUser) &&
                  ss['documentId'] != userDocId) {
                addedUsernames.add(otherUser);

                String bio = ss['about'];
                String documentId = ss['documentId'];

                if (ss['pp'].runtimeType == String) {
                  String profile = ss['pp'];
                  usernameMap[otherUser] = [documentId, bio, profile];
                } else {
                  Blob profile = ss['pp'];
                  usernameMap[otherUser] = [documentId, bio, profile];
                }
              }
            }
          }
        }
        return usernameMap;
      } else {
        return {};
      }
    } catch (error) {
      if (kDebugMode) {
        print('Hata: $error');
      }
      return {};
    }
  }

  Future<List<Map<String, dynamic>>?> getSpecificUserData(
      List documentIds) async {
    List<Map<String, dynamic>> userDataList = [];

    try {
      for (String documentId in documentIds) {
        DocumentSnapshot documentSnapshot =
            await usersCollection.doc(documentId).get();

        if (documentSnapshot.exists) {
          Map<String, dynamic> userData = {
            'documentId': documentId,
            'pp': documentSnapshot['pp'],
            'username': documentSnapshot['username'],
            'about': documentSnapshot['about'],
          };
          userDataList.add(userData);
        }
      }

      return userDataList;
    } catch (error) {
      if (kDebugMode) {
        print('Hata: $error');
      }
      return null;
    }
  }

  Future<List<searchUserDatas>> searchUsers(String searchTerm) async {
    List<searchUserDatas> userList = [];
    try {
      // Firestore sorgusu
      QuerySnapshot querySnapshot = await usersCollection
          .where('username', isGreaterThanOrEqualTo: searchTerm)
          .where('username', isLessThan: '${searchTerm}z')
          .limit(25)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          userList.add(searchUserDatas(
            username: doc['username'],
            pp: doc['pp'],
            documentId: doc.id,
            about: doc['about'],
          ));
        }
      } else {
        if (kDebugMode) {
          print('Kullanıcı bulunamadı');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Hata oluştu: $e');
      }
    }

    return userList;
  }
}
