// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muppin_app/database/followRequest.dart';
import 'package:muppin_app/database/followers.dart';
import 'package:muppin_app/database/followings.dart';
import 'package:muppin_app/database/local/localdb.dart';
import 'package:muppin_app/transactions/badges.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/dataprovider.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/transactions/shareds.dart';
import 'package:faker/faker.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: use_key_in_widget_constructors
class HomeScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

// ignore: camel_case_types
class _HomeScreenState extends State<HomeScreen> {
  String account = "";
  int _currentIndex = 1;
  Map<String, List> suggests = {};
  bool loadState = true;

  String followersCount = "0";
  String followingCount = "0";
  String aboutText = "Hata! Yüklenemedi.";
  String loadText = "Yükleniyor..";
  String memberSince = "Bilinmiyor.";

  List<String> allBadges = Badges().allBadges;
  List<dynamic> userBadges = [];
  Map<String, dynamic> userSocials = {};

  Map<String, dynamic> myStory = {};

  int notificationList = 0;

  List storyList = [];

  ImageProvider<Object> profilePF =
      const AssetImage('assets/images/default.png');

  ImageProvider<Object> othersPF =
      const AssetImage('assets/images/default.png');

  Map mainFriendAddBtnLoading = {};
  Map progressFriendAdd = {};

  @override
  void initState() {
    super.initState();
    initComps(false);
  }

  void initComps(bool profile) async {
    String docId = await Shareds.sharedCek("docId");
    if (docId == "Değer Bulunamadı" || docId == "") {
      AwesomeDialog(
        context: context,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: Colors.red,
        dismissOnTouchOutside: false,
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.error,
        animType: AnimType.topSlide,
        btnOkText: "Tamam",
        title: 'Bir şeyler ters gitti..',
        desc:
            'Hesabının verileri sağlam bir şekilde yüklenememiş gözüküyor. Lütfen tekrar giriş yap.',
        btnOkOnPress: () {
          Navigator.popAndPushNamed(context, "/signin");
        },
      ).show();
    } else {
      followersDb followersDatabase = followersDb();
      followings followingDatabase = followings();
      int getFollowersData = await followersDatabase.getFieldCount(docId);
      List<String> followingIds =
          await followingDatabase.getFollowingsIds(docId);
      int getFollowingData = followingIds.length;
      if (getFollowersData > 0 || getFollowingData > 0) {
        DataProvider().followersCount = getFollowersData.toString();
        DataProvider().followingCount = getFollowingData.toString();
        followersCount = getFollowersData.toString();
        followingCount = getFollowingData.toString();
      } else {
        DataProvider().followersCount = "0";
        DataProvider().followingCount = "0";
        followersCount = "0";
        followingCount = "0";
      }
      List exists = await localDatabase().isUserExistsAndGetDatas(docId);
      if ((exists[0])) {
        Map<String, dynamic> dataFields = exists[1];
        account = dataFields["accName"] ?? "";
        aboutText = dataFields["aboutText"] ?? "";
        memberSince = dataFields["since"] ?? "";
        String badges = dataFields["badges"] ?? "";
        if (badges != "") userBadges = extractNumbers(badges);
        String instagram = dataFields["instagram"] ?? "";
        String twitter = dataFields["twitter"] ?? "";
        String discord = dataFields["discord"] ?? "";
        String youtube = dataFields["youtube"] ?? "";
        if (instagram != "") userSocials["instagram"] = instagram;
        if (twitter != "") userSocials["twitter"] = twitter;
        if (discord != "") userSocials["discord"] = discord;
        if (youtube != "") userSocials["youtube"] = youtube;
        dynamic profilePhoto = dataFields["profilePhoto"];
        if (profilePhoto is Uint8List && profilePhoto.isNotEmpty) {
          String base64String = base64.encode(profilePhoto);
          ImageProvider imageProvider =
              MemoryImage(base64.decode(base64String));
          profilePF = imageProvider;
        }
        if (!profile) {
          database db = database();
          suggests = await db.getRandomUsernames();
          // ignore: unused_local_variable
          suggests.forEach(
            (key, value) async {
              List list = value;
              bool state =
                  await followRequestsDb().containsField(list[0], docId);
              if (state) {
                setState(() {
                  String doc = list[0];
                  mainFriendAddBtnLoading[doc] = true;
                });
              }
            },
          );
        }
        notificationList = await followRequestsDb().getFieldCount(docId);
        storyList = (await database().getSpecificUserData(followingIds))!;
        setState(() {
          loadState = false;
        });
      } else {
        AwesomeDialog(
          context: context,
          dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
          btnOkColor: Colors.red,
          dismissOnTouchOutside: false,
          titleTextStyle: const TextStyle(color: Colors.white),
          descTextStyle: const TextStyle(color: Colors.white),
          dialogType: DialogType.error,
          animType: AnimType.topSlide,
          btnOkText: "Tamam",
          title: 'Bir şeyler ters gitti..',
          desc:
              'Hesabının verileri sağlam bir şekilde yüklenememiş gözüküyor. Lütfen tekrar giriş yap.',
          btnOkOnPress: () {
            Navigator.popAndPushNamed(context, "/signin");
          },
        ).show();
      }
    }
  }

  List<int> extractNumbers(String input) {
    List<int> numbers = [];

    List<String> parts = input.split(",");
    for (String part in parts) {
      String trimmedPart = part.trim();
      if (trimmedPart.isNotEmpty) {
        int? number = int.tryParse(trimmedPart);
        if (number != null) {
          numbers.add(number);
        }
      }
    }
    return numbers;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void settingsClick() {
    Navigator.pushNamed(context, "/settings").then((value) async {
      if (value != null && value == "logout") {
        DataProvider().followersCount = "0";
        DataProvider().followingCount = "0";
        String docId = await Shareds.sharedCek("docId");
        localDatabase localDb = localDatabase();
        await localDb.deleteUser(docId);
        await Shareds.sharedEkleGuncelle("docId", "");
        await Shareds.sharedEkleGuncelle("loginState", "false");
        Navigator.popAndPushNamed(context, "/signin");
      }
    });
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
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            "assets/images/logo.png",
            width: 70,
            height: 100,
          ),
        ),
        actions: _currentIndex == 1
            ? [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, "/notifications",
                                arguments: suggests)
                            .then((value) async {
                          setState(() {
                            loadText = "Yükleniyor..";
                            loadState = true;
                          });
                          String docId = await Shareds.sharedCek("docId");
                          followersDb followersDatabase = followersDb();
                          followings followingDatabase = followings();
                          int getFollowersData =
                              await followersDatabase.getFieldCount(docId);
                          List<String> followingIds =
                              await followingDatabase.getFollowingsIds(docId);
                          int getFollowingData = followingIds.length;
                          if (getFollowersData > 0 || getFollowingData > 0) {
                            DataProvider().followersCount =
                                getFollowersData.toString();
                            DataProvider().followingCount =
                                getFollowingData.toString();
                            followersCount = getFollowersData.toString();
                            followingCount = getFollowingData.toString();
                          }
                          notificationList = 0;
                          setState(() {
                            loadText = "Yükleniyor..";
                            loadState = false;
                          });
                        });
                      },
                    ),
                    if (notificationList > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            notificationList.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.pushNamed(context, "/search");
                  },
                ),
              ]
            : (_currentIndex == 0
                ? [
                    IconButton(
                      icon: const Icon(Icons.more_vert_outlined),
                      color: Colors.white,
                      onPressed: () {
                        // Sohbetlerdeki Arama
                      },
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      color: Colors.white,
                      onPressed: settingsClick,
                    ),
                  ]),
      ),
      resizeToAvoidBottomInset: false,
      body: loadState == true
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
          : _buildBody(),
      bottomNavigationBar: CustomPaint(
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              topLeft: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: BottomNavigationBar(
              backgroundColor: const Color.fromARGB(154, 73, 47, 85),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: "Sohbetler",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Anasayfa",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profilim",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildSohbetler();
      case 1:
        return _buildAnasayfa(suggests);
      case 2:
        return _buildProfilim();
      default:
        return _buildAnasayfa(suggests);
    }
  }

  // Sohbetler
  Widget _buildSohbetler() {
    return Container(
      color: const Color.fromARGB(255, 32, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 5, right: 10, left: 10),
                itemCount: 10,
                itemBuilder: (context, index) {
                  var faker = Faker();
                  var name = faker.person.name();
                  if (name.length > 22) {
                    name = "${name.substring(0, 20)}...";
                  }
                  var image = faker.image.image();
                  var lastSeen = "Son görülme: 2 saat önce";

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/chat");
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromARGB(154, 99, 82, 107),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(image),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  lastSeen,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 234, 234, 234),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: FloatingActionButton(
                                heroTag: UniqueKey(),
                                mini: true,
                                backgroundColor:
                                    const Color.fromARGB(154, 195, 90, 255),
                                onPressed: () {
                                  // Arkadaş ekleme
                                },
                                child: const Icon(Icons.more_horiz_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  final double spacing = 10;

  Widget createBox(String name, dynamic profile, double height, String about,
      String documentId) {
    bool isVerified = name == "mustafawiped";
    bool isManager = name == "mustafawiped";

    if (profile is Blob) {
      Blob blobData = profile;
      Uint8List uint8listData = blobData.bytes;
      String base64String = base64.encode(uint8listData);
      ImageProvider imageProvider = MemoryImage(base64.decode(base64String));
      othersPF = imageProvider;
    } else {
      othersPF = const AssetImage('assets/images/default.png');
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, "/otherProfile", arguments: documentId)
            .then((value) {
          setState(() {
            followersCount = DataProvider().followersCount;
            followingCount = DataProvider().followingCount;
          });
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - spacing * 2,
        height: height,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 54, 54, 54),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 40,
              backgroundImage: othersPF,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                if (isVerified)
                  const Icon(
                    Icons.verified,
                    color: Colors.red,
                    size: 16,
                  ),
                if (isManager)
                  const Icon(
                    Icons.manage_accounts,
                    color: Colors.yellow,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Center(
              child: Text(
                about,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color.fromARGB(154, 210, 210, 210),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(
                  height: 30,
                  width: 30,
                  child: FloatingActionButton(
                    heroTag: UniqueKey(),
                    mini: true,
                    backgroundColor: const Color.fromARGB(154, 90, 4, 130),
                    onPressed: () async {
                      setState(() {
                        progressFriendAdd[documentId] = true;
                        mainFriendAddBtnLoading[documentId] = true;
                      });
                      String docId = await Shareds.sharedCek("docId");
                      bool state =
                          await followings().containsField(docId, documentId);
                      if (state) {
                        AwesomeDialog(
                          context: context,
                          dialogBackgroundColor:
                              const Color.fromARGB(255, 32, 32, 32),
                          btnOkColor: const Color.fromARGB(154, 73, 47, 85),
                          titleTextStyle: const TextStyle(color: Colors.white),
                          descTextStyle: const TextStyle(color: Colors.white),
                          dialogType: DialogType.error,
                          animType: AnimType.topSlide,
                          title: 'Hata! İşlem başarısız.',
                          desc: 'Zaten bu kişiyi takip ediyorsun.',
                          btnOkOnPress: () {},
                        ).show();
                        setState(() {
                          progressFriendAdd[documentId] = null;
                        });
                      } else {
                        bool otherState = await followRequestsDb()
                            .containsField(documentId, docId);
                        if (otherState) {
                          bool status = await followRequestsDb()
                              .deleteField(documentId, docId);
                          if (status) {
                            setState(() {
                              progressFriendAdd[documentId] = null;
                              mainFriendAddBtnLoading[documentId] = null;
                            });
                          } else {
                            AwesomeDialog(
                              context: context,
                              dialogBackgroundColor:
                                  const Color.fromARGB(255, 32, 32, 32),
                              btnOkColor: const Color.fromARGB(154, 73, 47, 85),
                              titleTextStyle:
                                  const TextStyle(color: Colors.white),
                              descTextStyle:
                                  const TextStyle(color: Colors.white),
                              dialogType: DialogType.error,
                              animType: AnimType.topSlide,
                              title: 'Hata! İşlem başarısız.',
                              desc:
                                  'Bir şeyler ters gitti. Daha sonra tekrar dene.',
                              btnOkOnPress: () {},
                            ).show();
                            setState(() {
                              progressFriendAdd[documentId] = null;
                            });
                          }
                        } else {
                          Future<bool> state = followRequestsDb()
                              .createOrUpdateDocument(documentId, docId);
                          state.then((value) {
                            if (value) {
                              setState(() {
                                progressFriendAdd[documentId] = null;
                              });
                            } else {
                              AwesomeDialog(
                                context: context,
                                dialogBackgroundColor:
                                    const Color.fromARGB(255, 32, 32, 32),
                                btnOkColor:
                                    const Color.fromARGB(154, 73, 47, 85),
                                titleTextStyle:
                                    const TextStyle(color: Colors.white),
                                descTextStyle:
                                    const TextStyle(color: Colors.white),
                                dialogType: DialogType.info,
                                animType: AnimType.topSlide,
                                title: 'Hata! İşlem başarısız.',
                                desc:
                                    'Bir şeyler ters gitti. Daha sonra tekrar dene.',
                                btnOkOnPress: () {},
                              ).show();
                              setState(() {
                                progressFriendAdd[documentId] = null;
                                mainFriendAddBtnLoading[documentId] = null;
                              });
                            }
                          });
                        }
                      }
                    },
                    child: (progressFriendAdd[documentId] != null)
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(255, 255, 255, 255)),
                            ),
                          )
                        : (mainFriendAddBtnLoading[documentId] is bool &&
                                mainFriendAddBtnLoading[documentId] == true)
                            ? const Icon(Icons.access_time)
                            : const Icon(Icons.person_add),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 50),
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: FloatingActionButton(
                      heroTag: UniqueKey(),
                      mini: true,
                      backgroundColor: const Color.fromARGB(154, 90, 4, 130),
                      onPressed: () {
                        // Sohbet istegi
                      },
                      child: const Icon(Icons.chat),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void storyErrorMsg() {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
      btnOkColor: const Color.fromARGB(154, 73, 47, 85),
      titleTextStyle: const TextStyle(color: Colors.white),
      descTextStyle: const TextStyle(color: Colors.white),
      dialogType: DialogType.error,
      animType: AnimType.topSlide,
      title: 'Hikaye Ekleme & Görme Aktif Değil.',
      desc:
          'Muppin, henüz Beta aşamasında olduğu için, hikaye ekleme aktif değildir. Aktif olduğunda bu kilit kalkacaktır.',
      btnOkOnPress: () {},
    ).show();
  }

  // Anasayfa sayfasının içeriği
  Widget _buildAnasayfa(Map<String, List> suggests) {
    return ScrollConfiguration(
      behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
      child: ListView(
        children: [
          const SizedBox(height: 10),
          // ignore: sized_box_for_whitespace
          Container(
            height: 80,
            child: Stack(
              children: [
                if (storyList.isNotEmpty)
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: storyList.length + 1,
                    itemExtent: 90,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        bool sa = true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: GestureDetector(
                            onTap: () {},
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: (myStory.isNotEmpty)
                                            ? (sa == false)
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color.fromARGB(
                                                          255, 214, 35, 246),
                                                      Color.fromARGB(
                                                          255, 73, 13, 177)
                                                    ],
                                                    begin: Alignment.topRight,
                                                    end: Alignment.bottomLeft,
                                                  )
                                                : const LinearGradient(
                                                    colors: [
                                                      Color.fromARGB(
                                                          255, 54, 54, 54),
                                                      Color.fromARGB(
                                                          255, 37, 37, 37)
                                                    ],
                                                    begin: Alignment.topRight,
                                                    end: Alignment.bottomLeft,
                                                  )
                                            : null,
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundImage: profilePF,
                                      ),
                                    ),
                                    if (sa == true)
                                      const Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          radius: 8,
                                          child: Icon(Icons.add,
                                              size: 10, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text("Hikayen",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      } else {
                        Map data = storyList[index - 1];
                        ImageProvider<Object> ppFf =
                            const AssetImage('assets/images/default.png');
                        if (data["pp"] is Blob) {
                          Blob blobData = data["pp"];
                          Uint8List uint8listData = blobData.bytes;
                          String base64String = base64.encode(uint8listData);
                          ImageProvider imageProvider =
                              MemoryImage(base64.decode(base64String));
                          ppFf = imageProvider;
                        } else {
                          ppFf = const AssetImage('assets/images/default.png');
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: GestureDetector(
                            onTap: () {},
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 54, 54, 54),
                                        Color.fromARGB(255, 37, 37, 37)
                                      ],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundImage: ppFf,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    (data["username"].length > 12)
                                        ? ("${data["username"].substring(0, 10)}...")
                                        : data["username"],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Muppin\'e Hoşgeldin!',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          'İşte senin için bulduğumuz birkaç kişi!',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (storyList.isNotEmpty)
                  GestureDetector(
                    onTap: storyErrorMsg,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 64, 64, 64)
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                if (storyList.isNotEmpty)
                  GestureDetector(
                    onTap: storyErrorMsg,
                    child: const Center(
                      child: Icon(
                        Icons.lock_clock,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          suggests.isEmpty
              ? const Center(
                  child: Text(
                    "Bir şeyler ters gitti :/",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: spacing,
                  runSpacing: spacing,
                  children: suggests.entries.map((entry) {
                    String name = entry.key;
                    return createBox(name, entry.value[2], 200, entry.value[1],
                        entry.value[0]);
                  }).toList(),
                ),
        ],
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

  double calculateTop(int itemCount) {
    if (itemCount == 1) {
      return 200.0;
    } else if (itemCount == 2) {
      return 310.0;
    } else if (itemCount == 3 || itemCount == 4) {
      return 310.0;
    }
    return 0.0;
  }

  double calculateContainerHeight(int itemCount) {
    if (itemCount == 1) {
      return 110.0;
    } else if (itemCount == 2) {
      return 180.0;
    } else if (itemCount == 3 || itemCount == 4) {
      return 240.0;
    }
    return 0.0;
  }

  // Profilim sayfasının içeriği
  Widget _buildProfilim() {
    return ScrollConfiguration(
      behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
      child: RefreshIndicator(
        backgroundColor: Colors.purple,
        color: Colors.white,
        onRefresh: () async {
          setState(() {
            loadState = true;
          });
          initComps(true);
        },
        child: ListView(
          children: [
            // İlk Container
            Container(
              width: 380,
              height: 200,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: const Color.fromARGB(255, 54, 54, 54),
                border: Border.all(width: 2.0, color: Colors.grey.shade800),
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
                                                  const EdgeInsets.all(10.0),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 32, 32, 32),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: const Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.info,
                                                    color: Colors.white,
                                                    size: 24.0,
                                                  ),
                                                  SizedBox(height: 10.0),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: Text(
                                                      "Muppin'in Kurucusu & Geliştiricisi",
                                                      style: TextStyle(
                                                        color: Colors.white,
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  String docId =
                                      await Shareds.sharedCek("docId");
                                  List followDetailList = [
                                    true,
                                    [account, docId],
                                    0
                                  ];
                                  Navigator.pushNamed(context, "/followDetail",
                                      arguments: followDetailList);
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
                                onTap: () async {
                                  String docId =
                                      await Shareds.sharedCek("docId");
                                  List followDetailList = [
                                    true,
                                    [account, docId],
                                    1
                                  ];
                                  Navigator.pushNamed(context, "/followDetail",
                                      arguments: followDetailList);
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
                                        fontSize: 14,
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
                          width: 5,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/profileEdit')
                                  .then((result) {
                                if (result is Map) {
                                  account = result["accName"];
                                  aboutText = result["aboutText"];
                                  userSocials = result["socials"];
                                  if (result["profilePhoto"] is String) {
                                    profilePF = const AssetImage(
                                        'assets/images/default.png');
                                  } else {
                                    profilePF = result["profilePhoto"];
                                  }
                                  setState(() {
                                    _currentIndex = 2;
                                  });
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color.fromARGB(
                                  255, 32, 32, 32), // Yazı rengi
                            ),
                            child: const Center(
                              child: Text(
                                "Profilini Düzenle",
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
                  : (userBadges.isEmpty && userSocials.length > 2)
                      ? 425
                      : (userBadges.isEmpty &&
                              userSocials.length <= 2 &&
                              userSocials.isNotEmpty)
                          ? 385
                          : (userBadges.isNotEmpty &&
                                  userSocials.length <= 2 &&
                                  userSocials.isNotEmpty)
                              ? 495
                              : (userBadges.isNotEmpty && userSocials.isEmpty)
                                  ? 415
                                  : 305,
              margin: const EdgeInsets.only(left: 5, right: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: const Color.fromARGB(255, 54, 54, 54),
                border: Border.all(width: 2.0, color: Colors.grey.shade800),
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
                              padding: const EdgeInsets.only(top: 0, left: 5),
                              child: Container(
                                width: 390,
                                height: 50,
                                margin: const EdgeInsets.only(
                                    top: 10.0, left: 5, right: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  color: const Color.fromARGB(255, 42, 42, 42),
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
                                                  const EdgeInsets.all(5.0),
                                              child: GestureDetector(
                                                onTap: () {
                                                  String text = (index == 0)
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
                                                    builder:
                                                        (BuildContext context) {
                                                      return Center(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: Container(
                                                            width: 200.0,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  32, 32, 32),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons.info,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 24.0,
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        10.0),
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: Text(
                                                                    text,
                                                                    style:
                                                                        const TextStyle(
                                                                      color: Colors
                                                                          .white,
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
                                                  backgroundImage: AssetImage(
                                                      allBadges[index]),
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
                                hintStyle: const TextStyle(color: Colors.white),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor:
                                    const Color.fromARGB(255, 42, 42, 42),
                                contentPadding: const EdgeInsets.all(20.0),
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
                              width: MediaQuery.of(context).size.width * 0.9,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: const Color.fromARGB(255, 42, 42, 42),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 10, left: 10),
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
                                      borderRadius: BorderRadius.circular(15.0),
                                      color:
                                          const Color.fromARGB(255, 42, 42, 42),
                                    ),
                                    child: Positioned(
                                      top: 0.0,
                                      left: 10.0,
                                      right: 10.0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children:
                                            userSocials.entries.map((value) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 0, left: 5),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              margin: const EdgeInsets.only(
                                                  top: 5.0, left: 15, right: 5),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                                color: const Color.fromARGB(
                                                    255, 42, 42, 42),
                                              ),
                                              child: Stack(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          String socialName =
                                                              value.key;
                                                          String socialAddress =
                                                              value.value;
                                                          String websiteURL =
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
                                                        child: CircleAvatar(
                                                          radius: 17.0,
                                                          backgroundImage:
                                                              AssetImage(
                                                                  getSocialLogo(
                                                                      value
                                                                          .key)),
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
}
