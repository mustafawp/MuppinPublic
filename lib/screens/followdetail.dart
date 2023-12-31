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
import 'package:muppin_app/transactions/dataprovider.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/transactions/shareds.dart';

// ignore: camel_case_types, use_key_in_widget_constructors

// ignore: camel_case_types
class followDetail extends StatefulWidget {
  const followDetail({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FollowDetailState createState() => _FollowDetailState();
}

class _FollowDetailState extends State<followDetail> {
  bool inLoading = true;

  bool himself = false;
  String username = "";
  String viewerDocId = "";

  List followersList = [];
  List followingList = [];
  List followbackList = [];

  String fbControlString = "";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      initConfigures();
    });
  }

  void initConfigures() async {
    viewerDocId = await Shareds.sharedCek("docId");
    List dataLists = ModalRoute.of(context)?.settings.arguments as List;
    himself = dataLists[0];
    List<String> otherDatas = dataLists[1];
    username = otherDatas[0];
    String otherDocId = otherDatas[1];
    List otherFollowersList = await followersDb().getFollowersIds(otherDocId);
    List otherFollowingList = await followings().getFollowingsIds(otherDocId);
    followersList = (await database().getSpecificUserData(otherFollowersList))!;
    followingList = (await database().getSpecificUserData(otherFollowingList))!;
    if (himself) {
      DataProvider().followersCount = otherFollowersList.length.toString();
      DataProvider().followingCount = otherFollowingList.length.toString();
      for (Map<String, dynamic> followingUserData in followingList) {
        String followingDocumentId = followingUserData['documentId'];
        bool isFollowingInFollowersList = followersList.any(
            (followerUserData) =>
                followerUserData['documentId'] == followingDocumentId);

        if (!isFollowingInFollowersList) {
          followbackList.add(followingUserData);
        }
      }
    } else {
      List fbControl = await followings().getFollowingsIds(viewerDocId);
      for (String data in fbControl) {
        fbControlString += " $data";
      }
    }
    setState(() {
      inLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List dataLists = ModalRoute.of(context)?.settings.arguments as List;
    return DefaultTabController(
      initialIndex: dataLists[2],
      length: himself ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                "assets/images/logo.png",
                width: 70,
                height: 100,
              ),
              const SizedBox(width: 8),
              Text(
                inLoading ? "| Yükleniyor.." : "| $username",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(154, 73, 47, 85),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.transparent,
            isScrollable: himself ? true : false,
            unselectedLabelStyle: const TextStyle(
              fontSize: 14.0,
            ),
            labelStyle: const TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(
                  text: inLoading
                      ? "Yükleniyor.."
                      : "${followersList.length} Takipçi"),
              Tab(
                  text: inLoading
                      ? "Yükleniyor.."
                      : "${followingList.length} Takip Edilen"),
              if (himself)
                Tab(text: "${followbackList.length} Geri Takip Yapmayanlar"),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        body: ScrollConfiguration(
          behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
          child: inLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 16),
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
              : TabBarView(
                  children: [
                    FollowList("followers", followersList, himself, viewerDocId,
                        fbControlString),
                    FollowList("followings", followingList, himself,
                        viewerDocId, fbControlString),
                    if (himself)
                      FollowList("notfollowback", followbackList, himself,
                          viewerDocId, fbControlString),
                  ],
                ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class FollowList extends StatefulWidget {
  final String listType;
  final List datas;
  String viewerFollowings;
  final bool himself;
  final String docId;

  FollowList(this.listType, this.datas, this.himself, this.docId,
      this.viewerFollowings,
      {Key? key})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _FollowListState createState() => _FollowListState();
}

class _FollowListState extends State<FollowList> {
  bool loading = true;
  ImageProvider getProfileImage(dynamic blobData) {
    if (blobData is Blob) {
      Uint8List uint8listData = blobData.bytes;
      String base64String = base64.encode(uint8listData);
      return MemoryImage(Uint8List.fromList(base64.decode(base64String)));
    } else {
      return const AssetImage('assets/images/default.png');
    }
  }

  bool getButtonVisibility(documentId) {
    return widget.docId.toString() == documentId.toString();
  }

  Map<String, bool> sa = {};

  String getButtonText(documentId) {
    if (widget.himself) {
      return (widget.listType == "followers") ? "Sil" : "Kaldır";
    }
    if (sa[documentId] == null) {
    } else if (sa[documentId] as bool) {
      sa[documentId] = false;
      return "Gönderildi.";
    } else if (sa[documentId] == false) {
      sa.remove(documentId);
      return "Gönderildi.";
    }
    return widget.viewerFollowings.contains(documentId) ? "Kaldır" : "Takip Et";
  }

  List filteredDatas = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      filteredDatas = widget.datas;
      setState(() {
        loading = false;
      });
    });
  }

  void filterData(String query) async {
    setState(() {
      loading = true;
    });
    // ignore: await_only_futures
    filteredDatas = await (widget.datas as List<Map<String, dynamic>>)
        .where((data) => data['username']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 16),
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
        : Container(
            padding: const EdgeInsets.only(top: 5),
            color: const Color.fromARGB(255, 32, 32, 32),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 5, left: 20, right: 20, bottom: 10),
                  child: TextField(
                    maxLength: 20,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.purple,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      filterData(value);
                    },
                    maxLines: 1,
                    onChanged: (String value) {
                      filterData(value);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ara..',
                      hintStyle:
                          TextStyle(color: Color.fromARGB(255, 123, 123, 123)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.purple,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(255, 54, 54, 54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0.0,
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      counterText: "",
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDatas.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {
                          String documentId =
                              filteredDatas[index]["documentId"];
                          Navigator.pushNamed(context, "/otherProfile",
                              arguments: documentId);
                        },
                        leading: CircleAvatar(
                          backgroundImage:
                              getProfileImage(filteredDatas[index]["pp"]),
                        ),
                        title: Row(
                          children: [
                            Text(
                              filteredDatas[index]["username"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (filteredDatas[index]["username"] ==
                                "mustafawiped")
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
                                            padding: const EdgeInsets.all(10.0),
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
                              ),
                          ],
                        ),
                        subtitle: Text(
                          filteredDatas[index]["about"],
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: getButtonVisibility(
                                filteredDatas[index]["documentId"])
                            ? null
                            : ElevatedButton(
                                onPressed: () async {
                                  if (widget.himself) {
                                    if (widget.listType == "followers") {
                                      AwesomeDialog(
                                        context: context,
                                        dismissOnTouchOutside: false,
                                        dialogBackgroundColor:
                                            const Color.fromARGB(
                                                255, 32, 32, 32),
                                        btnOkColor: Colors.red,
                                        btnCancelColor: Colors.blue,
                                        titleTextStyle: const TextStyle(
                                            color: Colors.white),
                                        descTextStyle: const TextStyle(
                                            color: Colors.white),
                                        dialogType: DialogType.warning,
                                        animType: AnimType.topSlide,
                                        btnOkText: "Çıkar",
                                        btnCancelText: "Vazgeç",
                                        title: 'Hey! bu işin geri dönüşü yok.',
                                        desc:
                                            'Eğer ${filteredDatas[index]["username"]} takipçilerinin arasından çıkarırsan, seni takip etmek için tekrar istek göndermesi gerekecek.',
                                        btnOkOnPress: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return Center(
                                                child: Container(
                                                  width: 150.0,
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  child: const Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      CircularProgressIndicator(
                                                        color: Color.fromARGB(
                                                            255, 225, 57, 255),
                                                      ),
                                                      SizedBox(height: 10.0),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                          Future.delayed(
                                              const Duration(milliseconds: 1),
                                              () async {
                                            String viewerId = widget.docId;
                                            String otherUserId =
                                                filteredDatas[index]
                                                    ["documentId"];
                                            await followersDb().deleteField(
                                                viewerId, otherUserId);
                                            await followings().deleteField(
                                                otherUserId, viewerId);
                                            int followersCount = int.parse(
                                                DataProvider().followersCount);
                                            followersCount--;
                                            if (followersCount < 0) {
                                              followersCount = 0;
                                            }
                                            DataProvider().followersCount =
                                                followersCount.toString();
                                            Navigator.of(context).pop();
                                            setState(() {
                                              filteredDatas.removeAt(index);
                                            });
                                          });
                                        },
                                        btnCancelOnPress: () {},
                                      ).show();
                                    } else {
                                      showModalBottomSheet(
                                        backgroundColor: Colors.transparent,
                                        context: context,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        builder: (BuildContext context) {
                                          return Container(
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 32, 32, 32),
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'Emin misin?',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                const SizedBox(height: 16.0),
                                                RichText(
                                                  textAlign: TextAlign.center,
                                                  text: TextSpan(
                                                    children: [
                                                      const TextSpan(
                                                        text: 'Eğer ',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            filteredDatas[index]
                                                                ["username"],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const TextSpan(
                                                        text:
                                                            ' takip ettiğin kişiler arasından çıkarırsan, tekrar takip etmek istediğinde istek göndermen gerekecek.',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 16.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                        minimumSize: const Size(
                                                            150,
                                                            40), // Buton genişliği ve yüksekliği
                                                      ),
                                                      child: const Text(
                                                          "Vazgeç",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (BuildContext
                                                              context) {
                                                            return Center(
                                                              child: Container(
                                                                width: 150.0,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        10.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.7),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10.0),
                                                                ),
                                                                child:
                                                                    const Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    CircularProgressIndicator(
                                                                      color: Color.fromARGB(
                                                                          255,
                                                                          225,
                                                                          57,
                                                                          255),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            10.0),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                        Future.delayed(
                                                            const Duration(
                                                                milliseconds:
                                                                    1),
                                                            () async {
                                                          String viewerId =
                                                              widget.docId;
                                                          String otherUserId =
                                                              filteredDatas[
                                                                      index][
                                                                  "documentId"];
                                                          await followersDb()
                                                              .deleteField(
                                                                  otherUserId,
                                                                  viewerId);
                                                          await followings()
                                                              .deleteField(
                                                                  viewerId,
                                                                  otherUserId);
                                                          int followingCount =
                                                              int.parse(
                                                                  DataProvider()
                                                                      .followingCount);
                                                          followingCount--;
                                                          if (followingCount <
                                                              0) {
                                                            followingCount = 0;
                                                          }
                                                          DataProvider()
                                                                  .followingCount =
                                                              followingCount
                                                                  .toString();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            filteredDatas
                                                                .removeAt(
                                                                    index);
                                                          });
                                                          Navigator.pop(
                                                              context);
                                                        });
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                        minimumSize:
                                                            const Size(150, 40),
                                                      ),
                                                      child: const Text("Çıkar",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  } else {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return Center(
                                          child: Container(
                                            width: 150.0,
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.7),
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: const Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircularProgressIndicator(
                                                  color: Color.fromARGB(
                                                      255, 225, 57, 255),
                                                ),
                                                SizedBox(height: 10.0),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                    String transaction = getButtonText(
                                        filteredDatas[index]["documentId"]);
                                    if (transaction == "Takip Et") {
                                      Future<bool> state = followRequestsDb()
                                          .createOrUpdateDocument(
                                              filteredDatas[index]
                                                  ["documentId"],
                                              widget.docId);
                                      state.then((value) {
                                        if (!value) {
                                          Navigator.of(context).pop();
                                          AwesomeDialog(
                                            context: context,
                                            dialogBackgroundColor:
                                                const Color.fromARGB(
                                                    255, 32, 32, 32),
                                            btnOkColor: const Color.fromARGB(
                                                154, 73, 47, 85),
                                            titleTextStyle: const TextStyle(
                                                color: Colors.white),
                                            descTextStyle: const TextStyle(
                                                color: Colors.white),
                                            dialogType: DialogType.error,
                                            animType: AnimType.topSlide,
                                            title: 'İşlem Başarısız.',
                                            desc:
                                                'Takip isteği gönderilemedi. Lütfen daha sonra tekrar dene.',
                                            btnOkOnPress: () {},
                                          ).show();
                                          setState(() {});
                                        } else {
                                          Navigator.of(context).pop();
                                          sa[filteredDatas[index]
                                              ["documentId"]] = true;
                                          setState(() {});
                                        }
                                      });
                                    } else if (transaction == "Gönderildi.") {
                                      bool state = await followRequestsDb()
                                          .deleteField(
                                              filteredDatas[index]
                                                  ["documentId"],
                                              widget.docId);
                                      if (state) {
                                        Navigator.of(context).pop();
                                        setState(() {});
                                      } else {
                                        Navigator.of(context).pop();
                                        AwesomeDialog(
                                          context: context,
                                          dialogBackgroundColor:
                                              const Color.fromARGB(
                                                  255, 32, 32, 32),
                                          btnOkColor: const Color.fromARGB(
                                              154, 73, 47, 85),
                                          titleTextStyle: const TextStyle(
                                              color: Colors.white),
                                          descTextStyle: const TextStyle(
                                              color: Colors.white),
                                          dialogType: DialogType.error,
                                          animType: AnimType.topSlide,
                                          title: 'İşlem Başarısız.',
                                          desc:
                                              'Takip isteği geri çekilemedi. Lütfen daha sonra tekrar dene.',
                                          btnOkOnPress: () {},
                                        ).show();
                                        setState(() {});
                                      }
                                    } else if (transaction == "Kaldır") {
                                      if (widget.listType == "followers") {
                                        Navigator.of(context).pop();
                                        showModalBottomSheet(
                                          backgroundColor: Colors.transparent,
                                          context: context,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          builder: (BuildContext context) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 32, 32, 32),
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Emin misin?',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  const SizedBox(height: 16.0),
                                                  RichText(
                                                    textAlign: TextAlign.center,
                                                    text: TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                          text: 'Eğer ',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        TextSpan(
                                                          text: filteredDatas[
                                                                  index]
                                                              ["username"],
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const TextSpan(
                                                          text:
                                                              ' takip ettiğin kişiler arasından çıkarırsan, tekrar takip etmek istediğinde istek göndermen gerekecek.',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16.0),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.0),
                                                          ),
                                                          minimumSize: const Size(
                                                              150,
                                                              40), // Buton genişliği ve yüksekliği
                                                        ),
                                                        child: const Text(
                                                            "Vazgeç",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            barrierDismissible:
                                                                false,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return Center(
                                                                child:
                                                                    Container(
                                                                  width: 150.0,
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.7),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10.0),
                                                                  ),
                                                                  child:
                                                                      const Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      CircularProgressIndicator(
                                                                        color: Color.fromARGB(
                                                                            255,
                                                                            225,
                                                                            57,
                                                                            255),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              10.0),
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          );
                                                          Future.delayed(
                                                              const Duration(
                                                                  milliseconds:
                                                                      1),
                                                              () async {
                                                            bool state = await followersDb()
                                                                .deleteField(
                                                                    filteredDatas[
                                                                            index]
                                                                        [
                                                                        "documentId"],
                                                                    widget
                                                                        .docId);
                                                            bool state2 = await followings()
                                                                .deleteField(
                                                                    widget
                                                                        .docId,
                                                                    filteredDatas[
                                                                            index]
                                                                        [
                                                                        "documentId"]);
                                                            if (state &&
                                                                state2) {
                                                              setState(() {});
                                                            } else {
                                                              AwesomeDialog(
                                                                context:
                                                                    context,
                                                                dialogBackgroundColor:
                                                                    const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        32,
                                                                        32,
                                                                        32),
                                                                btnOkColor:
                                                                    const Color
                                                                        .fromARGB(
                                                                        154,
                                                                        73,
                                                                        47,
                                                                        85),
                                                                titleTextStyle:
                                                                    const TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                descTextStyle:
                                                                    const TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                dialogType:
                                                                    DialogType
                                                                        .error,
                                                                animType: AnimType
                                                                    .topSlide,
                                                                title:
                                                                    'İşlem Başarısız.',
                                                                desc:
                                                                    'Takipten çıkarken bir sorun oluştu. Lütfen daha sonra tekrar dene.',
                                                                btnOkOnPress:
                                                                    () {},
                                                              ).show();
                                                              setState(() {});
                                                            }
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            setState(() {
                                                              String
                                                                  deleteString =
                                                                  filteredDatas[
                                                                          index]
                                                                      [
                                                                      "documentId"];
                                                              String updateString = widget
                                                                  .viewerFollowings
                                                                  .replaceAll(
                                                                      deleteString,
                                                                      "");
                                                              widget.viewerFollowings =
                                                                  updateString;
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.0),
                                                          ),
                                                          minimumSize:
                                                              const Size(
                                                                  150, 40),
                                                        ),
                                                        child: const Text(
                                                            "Çıkar",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      } else {}
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(154, 73, 47, 85),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: Text(
                                    getButtonText(
                                        filteredDatas[index]["documentId"]),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
