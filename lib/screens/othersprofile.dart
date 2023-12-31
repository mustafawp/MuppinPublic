import 'dart:convert';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muppin_app/database/followRequest.dart';
import 'package:muppin_app/database/followers.dart';
import 'package:muppin_app/database/followings.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/badges.dart';
import 'package:muppin_app/transactions/dataprovider.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/database/reports.dart';
import 'package:muppin_app/transactions/shareds.dart';
import 'package:muppin_app/transactions/userdata.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: camel_case_types, use_key_in_widget_constructors
class othersProfileScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _othersProfileScreenState createState() => _othersProfileScreenState();
}

// ignore: camel_case_types
class _othersProfileScreenState extends State<othersProfileScreen> {
  String documentId = "";
  String account = "unknown";
  String followersCount = "0";
  String followingCount = "0";
  ImageProvider<Object> profilePF =
      const AssetImage('assets/images/default.png');

  List<dynamic> userBadges = [];
  Map<String, dynamic> userSocials = {};
  List<String> allBadges = Badges().allBadges;

  String aboutText = "Hata! Yüklenemedi.";
  String loadText = "Yükleniyor..";
  String memberSince = "Bilinmiyor.";

  bool loading = true;

  bool himself = true;
  bool isFollowing = false;
  bool followRequest = false;

  Color followBtnBgColor = Colors.blue;
  String followBtnText = "Takip Et";
  bool buttonLoading = false;

  String viewerDocId = "";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      initConfigures();
    });
  }

  void initConfigures() async {
    documentId = ModalRoute.of(context)?.settings.arguments as String;
    List<String> desiredDatas = [
      "username",
      "socials",
      "joined",
      "pp",
      "badges",
      "about"
    ];
    UserData getUserDatas = await database()
        .getUserDatasFromFieldName(desiredDatas, documentId, "documentId");
    if (getUserDatas.success) {
      List dataList = getUserDatas.data;
      account = dataList[0];
      userSocials = dataList[1];
      memberSince = dataList[2];
      if (dataList[3] is Blob) {
        Blob blobData = dataList[3];
        Uint8List uint8listData = blobData.bytes;
        String base64String = base64.encode(uint8listData);
        ImageProvider imageProvider = MemoryImage(base64.decode(base64String));
        profilePF = imageProvider;
      }
      userBadges = dataList[4];
      aboutText = dataList[5];
      viewerDocId = await Shareds.sharedCek("docId");
      if (documentId == viewerDocId) {
        himself = true;
        followBtnBgColor = const Color.fromARGB(255, 32, 32, 32);
        followBtnText = "Profili Düzenle";
      } else {
        himself = false;
      }
      int getFollowersData = await followersDb().getFieldCount(documentId);
      int getFollowingData = await followings().getFieldCount(documentId);
      if (getFollowersData > 0 || getFollowingData > 0) {
        followersCount = getFollowersData.toString();
        followingCount = getFollowingData.toString();
      }
      if (himself) {
        DataProvider().followersCount = getFollowersData.toString();
        DataProvider().followingCount = getFollowingData.toString();
      }

      isFollowing = await followings().containsField(viewerDocId, documentId);
      List followRequestsList =
          await followRequestsDb().getFieldName(documentId, "A");
      followRequest = followRequestsList.contains(viewerDocId);
      if (isFollowing) {
        followBtnBgColor = const Color.fromARGB(255, 32, 32, 32);
        followBtnText = "Takiptesin";
      } else if (followRequest) {
        followBtnBgColor = const Color.fromARGB(255, 32, 32, 32);
        followBtnText = "Gönderildi";
      } else if (followingCount.contains(viewerDocId)) {
        followBtnText = "Geri Takip";
      }
      setState(() {
        loading = false;
      });
    } else {
      // ignore: use_build_context_synchronously
      AwesomeDialog(
        context: context,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: const Color.fromARGB(154, 73, 47, 85),
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.error,
        animType: AnimType.topSlide,
        title: 'Hata!',
        desc: 'Bir şeyler ters gitti, internet bağlantını kontrol et.',
        btnOkOnPress: () {},
      ).show();
    }
  }

  void clickFollowBtn() {
    if (!himself) {
      if (isFollowing) {
        AwesomeDialog(
          context: context,
          dismissOnTouchOutside: false,
          dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
          btnOkColor: Colors.red,
          btnCancelColor: Colors.blue,
          titleTextStyle: const TextStyle(color: Colors.white),
          descTextStyle: const TextStyle(color: Colors.white),
          dialogType: DialogType.warning,
          animType: AnimType.bottomSlide,
          btnOkText: "Takipten Çık",
          btnCancelText: "Vazgeç",
          title: 'Gerçekten takipten çıkmak mı istiyorsun?',
          desc:
              'Takipten çıkarsan, bir daha takip etmek istediğinde tekrar istek göndereceksin.',
          btnOkOnPress: unfollowThisUser,
          btnCancelOnPress: () {},
        ).show();
      } else {
        if (followRequest) {
          withdrawFollowRequest();
        } else {
          followThisUser();
        }
      }
    } else {
      Navigator.pushNamed(context, '/profileEdit').then((result) {
        if (result is Map) {
          account = result["accName"];
          aboutText = result["aboutText"];
          userSocials = result["socials"];
          if (result["profilePhoto"] is String) {
            profilePF = const AssetImage('assets/images/default.png');
          } else {
            profilePF = result["profilePhoto"];
          }
          setState(() {});
        }
      });
    }
  }

  void followThisUser() async {
    buttonLoading = true;
    followRequest = true;
    setState(() {
      followBtnBgColor = const Color.fromARGB(255, 32, 32, 32);
      followBtnText = "Gönderildi";
    });
    Future<bool> state =
        followRequestsDb().createOrUpdateDocument(documentId, viewerDocId);
    state.then((value) {
      if (!value) {
        // ignore: use_build_context_synchronously
        AwesomeDialog(
          context: context,
          dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
          btnOkColor: const Color.fromARGB(154, 73, 47, 85),
          titleTextStyle: const TextStyle(color: Colors.white),
          descTextStyle: const TextStyle(color: Colors.white),
          dialogType: DialogType.error,
          animType: AnimType.topSlide,
          title: 'İşlem Başarısız.',
          desc: 'Takip isteği gönderilemedi. Lütfen daha sonra tekrar dene.',
          btnOkOnPress: () {},
        ).show();
        followRequest = false;
        setState(() {
          followBtnBgColor = Colors.blue;
          followBtnText = "Takip Et";
        });
      } else {
        setState(() {
          buttonLoading = false;
        });
      }
    });
  }

  void withdrawFollowRequest() async {
    setState(() {
      buttonLoading = true;
    });
    bool state = await followRequestsDb().deleteField(documentId, viewerDocId);
    if (state) {
      followRequest = false;
      bool contains =
          await followersDb().containsField(viewerDocId, documentId);
      setState(() {
        buttonLoading = false;
        followBtnBgColor = Colors.blue;
        if (contains) {
          followBtnText = "Geri Takip";
        } else {
          followBtnText = "Takip Et";
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      AwesomeDialog(
        context: context,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: const Color.fromARGB(154, 73, 47, 85),
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.error,
        animType: AnimType.topSlide,
        title: 'İşlem Başarısız.',
        desc: 'Takip isteği geri çekilemedi. Lütfen daha sonra tekrar dene.',
        btnOkOnPress: () {},
      ).show();
      setState(() {
        buttonLoading = false;
      });
    }
  }

  void unfollowThisUser() async {
    setState(() {
      buttonLoading = true;
    });
    bool state = await followersDb().deleteField(documentId, viewerDocId);
    bool state2 = await followings().deleteField(viewerDocId, documentId);
    if (state && state2) {
      isFollowing = false;
      setState(() {
        followBtnBgColor = Colors.blue;
        followBtnText = "Takip Et";
        buttonLoading = false;
      });
    } else {
      // ignore: use_build_context_synchronously
      AwesomeDialog(
        context: context,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: const Color.fromARGB(154, 73, 47, 85),
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.error,
        animType: AnimType.topSlide,
        title: 'İşlem Başarısız.',
        desc:
            'Takipten çıkarken bir sorun oluştu. Lütfen daha sonra tekrar dene.',
        btnOkOnPress: () {},
      ).show();
      setState(() {
        buttonLoading = false;
      });
    }
  }

  String selectedComplaint = "";
  String description = "";

  void _showReportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ReportMenu(
          onComplaintSelected: (complaint) {
            setState(() {
              selectedComplaint = complaint;
            });
          },
          onDescriptionSubmitted: (desc) {
            setState(() {
              description = desc;
            });
          },
          documentId: documentId,
          victimised: viewerDocId,
        );
      },
    );
  }

  void showQuestion() {
    if (followRequest) {
      AwesomeDialog(
        context: context,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: const Color.fromARGB(154, 73, 47, 85),
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.warning,
        animType: AnimType.topSlide,
        btnOkText: "Tamam",
        title: 'Hey! sakin adamım.',
        desc:
            '$account isimli kullanıcının takipçi & takip edilenler kısmını görmen için onu takip ediyor olman gerek.',
        btnOkOnPress: () {},
      ).show();
    } else {
      AwesomeDialog(
              context: context,
              dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
              btnOkColor: Colors.green,
              btnCancelColor: Colors.blue,
              titleTextStyle: const TextStyle(color: Colors.white),
              descTextStyle: const TextStyle(color: Colors.white),
              dialogType: DialogType.warning,
              animType: AnimType.topSlide,
              btnOkText: "İstek Gönder",
              btnCancelText: "Sonra",
              title: 'Hey! sakin.',
              desc:
                  '$account isimli kullanıcının takipçi & takip edilenler kısmını görmen için onu takip ediyor olman gerek.',
              btnOkOnPress: () {
                followThisUser();
              },
              btnCancelOnPress: () {})
          .show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
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
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          ],
        ),
        actions: himself
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.report),
                  color: Colors.white,
                  onPressed: _showReportMenu,
                ),
              ],
      ),
      body: ScrollConfiguration(
        behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
        child: loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      loadText,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ],
                ),
              )
            : ListView(
                children: [
                  Container(
                    width: 380,
                    height: 200,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: const Color.fromARGB(255, 54, 54, 54),
                      border:
                          Border.all(width: 2.0, color: Colors.grey.shade800),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 30.0,
                          left: 130.0,
                          right: 16.0,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      account,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                      ),
                                    ),
                                    if (account == "mustafawiped")
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Center(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Container(
                                                    width: 250.0,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10.0),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 32, 32, 32),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    child: const Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.info,
                                                          color: Colors.white,
                                                          size: 24.0,
                                                        ),
                                                        SizedBox(height: 10.0),
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: Text(
                                                            "Muppin'in Kurucusu & Geliştiricisi",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: const Row(
                                          children: [
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
                                      )
                                  ],
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (isFollowing || himself) {
                                          List followDetailList = [
                                            himself,
                                            [account, documentId],
                                            0
                                          ];
                                          Navigator.pushNamed(
                                                  context, "/followDetail",
                                                  arguments: followDetailList)
                                              .then((value) {
                                            setState(() {
                                              if (himself) {
                                                followersCount = DataProvider()
                                                    .followersCount;
                                                followingCount = DataProvider()
                                                    .followingCount;
                                              }
                                            });
                                          });
                                        } else {
                                          showQuestion();
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          const Text(
                                            "Takipçi",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            followersCount,
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (isFollowing || himself) {
                                          List followDetailList = [
                                            himself,
                                            [account, documentId],
                                            1
                                          ];
                                          Navigator.pushNamed(
                                                  context, "/followDetail",
                                                  arguments: followDetailList)
                                              .then((value) {
                                            setState(() {
                                              if (himself) {
                                                followersCount = DataProvider()
                                                    .followersCount;
                                                followingCount = DataProvider()
                                                    .followingCount;
                                              }
                                            });
                                          });
                                        } else {
                                          showQuestion();
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          const Text(
                                            "Takip",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            followingCount,
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ]),
                        ),
                        Positioned(
                          top: 20.0,
                          left: 16.0,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.transparent,
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 120.0,
                                          backgroundImage: profilePF,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          account,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: CircleAvatar(
                              radius: 60.0,
                              backgroundImage: profilePF,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20.0,
                          left: 136.0,
                          right: 16.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(
                                width: 3,
                              ),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: clickFollowBtn,
                                  style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: followBtnBgColor),
                                  child: buttonLoading
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
                                      : Center(
                                          child: Text(
                                            followBtnText,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              himself
                                  ? const SizedBox()
                                  : Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: const Color.fromARGB(
                                              255, 32, 32, 32),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Mesaj",
                                            style: TextStyle(),
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(
                                width: 10,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // İkinci Container
                  Container(
                    width: 380, //435
                    height: (userBadges.isNotEmpty && userSocials.isNotEmpty)
                        ? 520
                        : (userBadges.isEmpty && userSocials.isNotEmpty)
                            ? 410
                            : (userBadges.isEmpty &&
                                    userSocials.length <= 2 &&
                                    userSocials.isNotEmpty)
                                ? 385
                                : (userBadges.isNotEmpty &&
                                        userSocials.length <= 2 &&
                                        userSocials.isNotEmpty)
                                    ? 495
                                    : (userBadges.isNotEmpty &&
                                            userSocials.isEmpty)
                                        ? 415
                                        : 305,
                    margin: const EdgeInsets.only(left: 5, right: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: const Color.fromARGB(255, 54, 54, 54),
                      border:
                          Border.all(width: 2.0, color: Colors.grey.shade800),
                    ),
                    child: Stack(
                      children: [
                        Visibility(
                          visible: userBadges.isNotEmpty,
                          child: Positioned(
                            top: 10.0,
                            left: 5.0,
                            right: 5.0,
                            child: Container(
                              width: 380,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.grey.shade800,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10, left: 10),
                                    child: Text(
                                      "Rozetler",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 0, left: 5),
                                    child: Container(
                                      width: 390,
                                      height: 50,
                                      margin: const EdgeInsets.only(
                                          top: 10.0, left: 5, right: 5),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        color: const Color.fromARGB(
                                            255, 42, 42, 42),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 0.0,
                                            left: 10.0,
                                            right: 10.0,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                for (int index in userBadges)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        String text = (index ==
                                                                0)
                                                            ? "Erken Dönem Destekçisi"
                                                            : index == 1
                                                                ? "Bug Hunter"
                                                                : index == 2
                                                                    ? "Premium Üye"
                                                                    : index == 3
                                                                        ? "Admin"
                                                                        : "Destekçi";
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return Center(
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: 200.0,
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        32,
                                                                        32,
                                                                        32),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10.0),
                                                                  ),
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      const Icon(
                                                                        Icons
                                                                            .info,
                                                                        color: Colors
                                                                            .white,
                                                                        size:
                                                                            24.0,
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              10.0),
                                                                      Material(
                                                                        color: Colors
                                                                            .transparent,
                                                                        child:
                                                                            Text(
                                                                          text,
                                                                          style:
                                                                              const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                15,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        radius: 20.0,
                                                        backgroundImage:
                                                            AssetImage(
                                                                allBadges[
                                                                    index]),
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 4. Container
                        Positioned(
                          top: userBadges.isNotEmpty ? 120.0 : 10.0,
                          left: 5.0,
                          right: 5.0,
                          child: Container(
                            width: 380,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade800,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10, left: 10),
                                  child: Text(
                                    "Hakkımda",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(7.0),
                                  child: TextFormField(
                                    enabled: false,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                    ),
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                      hintText: aboutText,
                                      hintStyle:
                                          const TextStyle(color: Colors.white),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor:
                                          const Color.fromARGB(255, 42, 42, 42),
                                      contentPadding:
                                          const EdgeInsets.all(20.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // katılım tarihi container
                        Positioned(
                          top: userBadges.isEmpty ? 200 : 310,
                          left: 5.0,
                          right: 5.0,
                          child: Container(
                            width: 380,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade800,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10, left: 10),
                                  child: Text(
                                    "Katılım Tarihi",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(7.0),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color:
                                          const Color.fromARGB(255, 42, 42, 42),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(13.0),
                                      child: Text(
                                        memberSince,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),

                        // 5. Container
                        Positioned(
                          top: userBadges.isEmpty ? 300 : 410.0,
                          left: 5.0,
                          right: 5.0,
                          child: Container(
                            width: 380,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade800,
                            ),
                            child: (userSocials.isEmpty)
                                ? null
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(top: 10, left: 10),
                                        child: Text(
                                          "Bağlantılar",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 0, left: 5, bottom: 10),
                                        child: Container(
                                          width: 400,
                                          height: 50,
                                          margin: const EdgeInsets.only(
                                              top: 10.0, left: 5, right: 5),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                            color: const Color.fromARGB(
                                                255, 42, 42, 42),
                                          ),
                                          child: Positioned(
                                            top: 0.0,
                                            left: 10.0,
                                            right: 10.0,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: userSocials.entries
                                                  .map((value) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 0, left: 5),
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 5.0,
                                                            left: 15,
                                                            right: 5),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15.0),
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 42, 42, 42),
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () {
                                                                String
                                                                    socialName =
                                                                    value.key;
                                                                String
                                                                    socialAddress =
                                                                    value.value;
                                                                String
                                                                    websiteURL =
                                                                    "https://www.muppinapp.com";
                                                                if (socialName ==
                                                                    "instagram") {
                                                                  websiteURL =
                                                                      "https://www.instagram.com/$socialAddress";
                                                                } else if (socialName ==
                                                                    "twitter") {
                                                                  websiteURL =
                                                                      "https://www.twitter.com/$socialAddress";
                                                                } else if (socialName ==
                                                                    "youtube") {
                                                                  websiteURL =
                                                                      "https://www.youtube.com/@$socialAddress";
                                                                } else {
                                                                  websiteURL =
                                                                      "https://www.discord.gg/$socialAddress";
                                                                }
                                                                Uri url = Uri.parse(
                                                                    websiteURL);

                                                                launchUrl(url);
                                                              },
                                                              child:
                                                                  CircleAvatar(
                                                                radius: 17.0,
                                                                backgroundImage:
                                                                    AssetImage(
                                                                        getSocialLogo(
                                                                            value.key)),
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String getSocialLogo(String socialName) {
    if (socialName == "instagram") {
      return "assets/socials/instagram.png";
    } else if (socialName == "twitter") {
      return "assets/socials/twitter.png";
    } else if (socialName == "discord") {
      return "assets/socials/discord.png";
    } else {
      return "assets/socials/youtube.png";
    }
  }

  String getSocialText(String socialName) {
    if (socialName == "instagram") {
      return "Instagram";
    } else if (socialName == "twitter") {
      return "X (twitter)";
    } else if (socialName == "discord") {
      return "Discord";
    } else {
      return "YouTube";
    }
  }
}

class ReportMenu extends StatefulWidget {
  final Function(String) onComplaintSelected;
  final Function(String) onDescriptionSubmitted;
  final String documentId;
  final String victimised;

  // ignore: prefer_const_constructors_in_immutables, use_key_in_widget_constructors
  ReportMenu(
      {required this.onComplaintSelected,
      required this.onDescriptionSubmitted,
      required this.documentId,
      required this.victimised});

  @override
  // ignore: library_private_types_in_public_api
  _ReportMenuState createState() => _ReportMenuState();
}

class _ReportMenuState extends State<ReportMenu> {
  String? selectedComplaint;
  TextEditingController descriptionController = TextEditingController();
  bool passButtonLoading = false;

  void passReportFunc() async {
    setState(() {
      passButtonLoading = true;
    });
    reports db = reports();
    Map<String, String> fields = {
      "complaint-type": selectedComplaint.toString(),
      "complaint-desc": descriptionController.text,
      "complained-account": widget.documentId,
      "complainant-account": widget.victimised,
    };
    await db.addReport(fields);
    setState(() {
      passButtonLoading = false;
    });
    // ignore: use_build_context_synchronously
    AwesomeDialog(
      context: context,
      dismissOnTouchOutside: false,
      dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
      btnOkColor: const Color.fromARGB(154, 73, 47, 85),
      titleTextStyle: const TextStyle(color: Colors.white),
      descTextStyle: const TextStyle(color: Colors.white),
      dialogType: DialogType.success,
      animType: AnimType.topSlide,
      title: 'Şikayetin için Teşekkürler!',
      desc:
          'Şikayetiniz başarıyla bize ulaştı! Sizler sayesinde daha güvenli bir ortam oluşturacağız!',
      btnOkOnPress: () {
        Navigator.pop(context);
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 38, 38, 38),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
          bottomLeft: Radius.circular(30.0),
          bottomRight: Radius.circular(30.0),
        ),
      ),
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedComplaint == null)
            Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Şikayet Türünü Seçin",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 21),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Divider(
                  color: Colors.white,
                ),
                for (String complaintOption in [
                  "Uygunsuz Hikaye Paylaşımı",
                  "Uygunsuz Kullanıcı Adı",
                  "Uygunsuz Profil Detayları",
                  "Yasadışı Faaliyetler",
                  "Kurumu / Kişiyi Taklit etme",
                  "Diğer"
                ])
                  ListTile(
                    title: Text(complaintOption),
                    titleTextStyle:
                        const TextStyle(color: Colors.white, fontSize: 16),
                    onTap: () {
                      widget.onComplaintSelected(complaintOption);
                      setState(() {
                        selectedComplaint = complaintOption;
                      });
                    },
                  ),
              ],
            ),
          if (selectedComplaint != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Şikayet Türü: $selectedComplaint",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLength: 40,
                      controller: descriptionController,
                      onChanged: (value) {
                        widget.onDescriptionSubmitted(value);
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Açıklama (isteğe bağlı)",
                        hintStyle: TextStyle(color: Colors.grey),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        counterStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: ElevatedButton(
                        onPressed: passReportFunc,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(154, 73, 47, 85),
                          ),
                          overlayColor: MaterialStateProperty.all<Color>(
                            Colors.transparent,
                          ),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                        child: passButtonLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 255, 255, 255)),
                                ))
                            : const Text(
                                "Şikayeti Gönder",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
