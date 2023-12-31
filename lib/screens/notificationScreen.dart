// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muppin_app/database/followRequest.dart';
import 'package:muppin_app/database/followers.dart';
import 'package:muppin_app/database/followings.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/transactions/shareds.dart';

// ignore: camel_case_types
class notificationScreen extends StatefulWidget {
  const notificationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<notificationScreen>
    with TickerProviderStateMixin {
  String viewerDocId = "";
  bool loadState = true;
  Map btnLoading = {};
  Map btnPassive = {};

  bool suggestLoadList = false;

  List<Map<String, dynamic>> notificationList = [];
  Map<String, bool> followButtonText = {};

  Map suggestsList = {};

  String fbControlString = "";

  // Bildirimler kısmındaki takip istekleri bölümü bitti.
  // Önerilenlere takip isteği gönderme kaldı onu da 2 dk da halledersin
  // basit zaten. Ondan sonra kişi aramaya geçersin ve anasayfa biter.

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      initConfigures();
    });
  }

  void initConfigures() async {
    suggestsList = Map.from(ModalRoute.of(context)?.settings.arguments as Map);
    viewerDocId = await Shareds.sharedCek("docId");
    Map<String, dynamic> docIdList =
        await followRequestsDb().getFieldName(viewerDocId, "B");
    if (docIdList.isNotEmpty) {
      List fbControl = await followings().getFollowingsIds(viewerDocId);
      for (String data in fbControl) {
        fbControlString += " $data";
      }
      notificationList =
          (await database().getSpecificUserData(docIdList.keys.toList()))!;
      for (Map<String, dynamic> notification in notificationList) {
        String documentId = notification["documentId"];
        dynamic dateValue = docIdList[documentId];

        if (dateValue != null) {
          notification["date"] = dateValue;
        }
      }
      // ignore: await_only_futures
      notificationList = await sortNotificationsByDate(notificationList);
      setState(() {
        loadState = false;
      });
    } else {
      setState(() {
        loadState = false;
      });
    }
  }

  List<Map<String, dynamic>> sortNotificationsByDate(
    List<Map<String, dynamic>> notifications,
  ) {
    notifications.sort((a, b) {
      DateTime dateA = convertTimestampToDateTime(a["date"]);
      DateTime dateB = convertTimestampToDateTime(b["date"]);
      return -dateA.compareTo(dateB);
    });
    return notifications;
  }

  DateTime convertTimestampToDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  String buttonText(text) {
    if (followButtonText[text] is bool) {
      return fbControlString.contains(text) ? "Takiptesin" : "Geri Takip";
    } else {
      return "Kabul Et";
    }
  }

  void acceptRequest(documentId) async {
    setState(() {
      btnLoading[documentId] = true;
    });
    followButtonText[documentId] = true;
    bool stateOne = await followings().addFollowing(documentId, viewerDocId);
    bool stateTwo = await followersDb().addFollower(viewerDocId, documentId);
    if (stateOne && stateTwo) {
      await followRequestsDb().deleteField(viewerDocId, documentId);
      setState(() {
        btnLoading[documentId] = null;
      });
    } else {
      AwesomeDialog(
        context: context,
        dismissOnTouchOutside: false,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: const Color.fromARGB(154, 73, 47, 85),
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.error,
        btnOkText: "Pekii..",
        animType: AnimType.topSlide,
        title: 'Takip isteği kabul edilemedi!',
        desc:
            'Bir şeyler ters gitti ve takip isteğini kabul edemedin. Daha sonra denemeye ne dersin?',
        btnOkOnPress: () {
          setState(() {
            btnLoading[documentId] = null;
          });
        },
      ).show();
    }
  }

  void deleteNotification(String documentId) async {
    await followRequestsDb().deleteField(viewerDocId, documentId);
    setState(() {
      notificationList.removeWhere((item) => item["documentId"] == documentId);
    });
  }

  void deleteSuggests(String key) async {
    setState(() {
      suggestsList.remove(key);
    });
  }

  dynamic getProfilePhoto(data) {
    if (data is Blob) {
      Blob blobData = data;
      Uint8List uint8listData = blobData.bytes;
      String base64String = base64.encode(uint8listData);
      ImageProvider imageProvider = MemoryImage(base64.decode(base64String));
      return imageProvider;
    } else {
      return const AssetImage('assets/images/default.png');
    }
  }

  String getNotificationDate(parameter) {
    if (parameter is Timestamp) {
      DateTime now = DateTime.now();
      DateTime dateTime = parameter.toDate();
      Duration difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return "${difference.inSeconds}sn";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}dk";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}sa";
      } else if (difference.inDays < 7) {
        return "${difference.inDays}g";
      } else if (difference.inDays < 30) {
        int weeks = (difference.inDays / 7).floor();
        return "${weeks}h";
      } else if (difference.inDays < 365) {
        int months = (difference.inDays / 30).floor();
        return "${months}ay";
      } else {
        int years = (difference.inDays / 365).floor();
        return "${years}y";
      }
    } else {
      return "";
    }
  }

  void unFollowingUser(String parameterIsDocId, String username) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 32, 32, 32),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Emin misin?',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16.0),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Hey! ',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' isimli kullanıcıyı takip ettiklerinin arasından çıkarmak istediğine emin misin?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(150, 40),
                    ),
                    child: const Text("Vazgeç",
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return WillPopScope(
                            onWillPop: () async {
                              return false;
                            },
                            child: Center(
                              child: Container(
                                width: 150.0,
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color.fromARGB(255, 225, 57, 255),
                                    ),
                                    SizedBox(height: 10.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                      Future.delayed(const Duration(milliseconds: 1), () async {
                        await followings()
                            .deleteField(viewerDocId, parameterIsDocId);
                        await followersDb()
                            .deleteField(parameterIsDocId, viewerDocId);
                        Navigator.of(context).pop();
                        setState(() {
                          fbControlString =
                              fbControlString.replaceAll(parameterIsDocId, "");
                        });
                        Navigator.pop(context);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(150, 40),
                    ),
                    child: const Text("Çıkar",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void followbackFunc(String parameterDocId) async {
    setState(() {
      btnLoading[parameterDocId] = true;
    });
    await followRequestsDb()
        .createOrUpdateDocument(parameterDocId, viewerDocId);
    btnPassive[parameterDocId] = true;
    setState(() {
      btnLoading[parameterDocId] = null;
    });
  }

  void suggestRequestMethod(String docId) async {
    setState(() {
      btnLoading[docId] = true;
    });
    bool state = await followings().containsField(viewerDocId, docId);
    if (state) {
      AwesomeDialog(
        context: context,
        dismissOnTouchOutside: false,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: const Color.fromARGB(154, 73, 47, 85),
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.error,
        btnOkText: "Haklısın, Pardon!",
        animType: AnimType.topSlide,
        title: 'Takip İsteği Gönderilemedi!',
        desc: 'Zaten bu kullanıcıyı takip ediyorsun.',
        btnOkOnPress: () {
          setState(() {
            btnLoading[docId] = null;
          });
        },
      ).show();
    } else {
      followbackFunc(docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(154, 73, 47, 85),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Image.asset(
              "assets/images/logo.png",
              width: 70,
              height: 100,
            ),
            const SizedBox(width: 8),
            const Text(
              "| Bildirimler",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      body: ScrollConfiguration(
        behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
        child: loadState == true
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 5),
                    Text(
                      "Yükleniyor..",
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 15),
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                backgroundColor: Colors.purple,
                color: Colors.white,
                onRefresh: () async {
                  setState(() {
                    loadState = true;
                  });
                  initConfigures();
                },
                child: ListView(
                  children: [
                    if (notificationList.isNotEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Color.fromARGB(154, 73, 47, 85),
                              child: Icon(
                                Icons.person_add,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Takip İstekleri",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  "istekleri onayla ya da reddet.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: notificationList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(50),
                                child: Text(
                                  "Henüz bildirim yok.",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                setState(() {
                                  loadState = true;
                                });
                                initConfigures();
                              },
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: notificationList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  Map<String, dynamic> userData =
                                      notificationList[index];
                                  return Dismissible(
                                    key: UniqueKey(),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onDismissed: (direction) {
                                      deleteNotification(
                                          userData["documentId"]);
                                    },
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            getProfilePhoto(userData["pp"]),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            userData["username"].toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (userData["username"] ==
                                              "mustafawiped")
                                            const Row(
                                              children: [
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                Icon(
                                                  Icons.verified,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                                Icon(
                                                  Icons.manage_accounts,
                                                  color: Colors.yellow,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            (followButtonText[
                                                        userData["documentId"]]
                                                    is bool)
                                                ? "Seni takip etmeye başladı.."
                                                : "Seni takip etmek istiyor.",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            followButtonText[
                                                        userData["documentId"]]
                                                    is bool
                                                ? ""
                                                : getNotificationDate(
                                                    userData["date"]),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                            context, "/otherProfile",
                                            arguments: userData["documentId"]);
                                      },
                                      trailing: ElevatedButton(
                                        onPressed: btnPassive[
                                                userData["documentId"]] is bool
                                            ? null
                                            : () {
                                                if (followButtonText[
                                                        userData["documentId"]]
                                                    is bool) {
                                                  if (buttonText(
                                                          userData["documentId"]
                                                              .toString()) ==
                                                      "Takiptesin") {
                                                    unFollowingUser(
                                                        userData["documentId"],
                                                        userData["username"]);
                                                  } else {
                                                    followbackFunc(
                                                        userData["documentId"]);
                                                  }
                                                } else {
                                                  acceptRequest(
                                                      userData["documentId"]);
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              btnPassive[userData["documentId"]]
                                                      is bool
                                                  ? const Color.fromARGB(
                                                      154, 43, 43, 43)
                                                  : const Color.fromARGB(
                                                      154, 73, 47, 85),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                        ),
                                        child: btnLoading[
                                                    userData["documentId"]] !=
                                                null
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Color.fromARGB(255,
                                                              255, 255, 255)),
                                                ),
                                              )
                                            : Text(
                                                btnPassive[userData[
                                                        "documentId"]] is bool
                                                    ? "Gönderildi"
                                                    : buttonText(
                                                        userData["documentId"]),
                                                style: TextStyle(
                                                    color: btnPassive[userData[
                                                                "documentId"]]
                                                            is bool
                                                        ? Colors.grey
                                                        : Colors.white),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    if (suggestsList.isNotEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.only(top: 15, left: 16.0, right: 16.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Önerilenler",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (suggestsList.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: suggestsList.entries.length,
                          itemBuilder: (BuildContext context, int index) {
                            MapEntry entry =
                                suggestsList.entries.elementAt(index);
                            return Dismissible(
                              key: UniqueKey(),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                deleteSuggests(entry.key);
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      getProfilePhoto(entry.value[2]),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      entry.key.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (entry.key.toString() == "mustafawiped")
                                      const Row(
                                        children: [
                                          SizedBox(
                                            width: 2,
                                          ),
                                          Icon(
                                            Icons.verified,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          Icon(
                                            Icons.manage_accounts,
                                            color: Colors.yellow,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  entry.value[1].toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context, "/otherProfile",
                                      arguments: entry.value[0]);
                                },
                                trailing: ElevatedButton(
                                  onPressed: btnPassive[entry.value[0]] is bool
                                      ? null
                                      : () {
                                          suggestRequestMethod(entry.value[0]);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: btnPassive[entry.value[0]]
                                            is bool
                                        ? const Color.fromARGB(154, 43, 43, 43)
                                        : const Color.fromARGB(154, 73, 47, 85),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                  child: btnLoading[entry.value[0]] != null
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color.fromARGB(
                                                        255, 255, 255, 255)),
                                          ),
                                        )
                                      : Text(
                                          btnPassive[entry.value[0]] is bool
                                              ? "Gönderildi"
                                              : "Takip Et",
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
