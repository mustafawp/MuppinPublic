import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muppin_app/database/local/localRecents.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/transactions/userdata.dart';

// ignore: camel_case_types
class searchScreen extends StatefulWidget {
  const searchScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _searchScreenState createState() => _searchScreenState();
}

// ignore: camel_case_types
class _searchScreenState extends State<searchScreen> {
  bool searchState = false;
  bool loadState = true;

  List<searchUserDatas> dataList = [];
  List<searchUserDatas> reserve = [];

  TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      initConfigures();
    });
  }

  void initConfigures() async {
    reserve = (await localRecents().getAllRecents())!;
    if (reserve.isNotEmpty) {
      dataList = List.from(reserve);
      dataList = dataList.reversed.toList();
    }
    setState(() {
      loadState = false;
    });
  }

  void searchUser(String searchText) async {
    setState(() {
      loadState = true;
    });
    if (searchText.isNotEmpty && containsLetter(searchText)) {
      searchState = true;
      dataList = await database().searchUsers(searchText);
      dataList = dataList.reversed.toList();
      setState(() {
        loadState = false;
      });
    } else {
      dataList = List.from(reserve);
      dataList = dataList.reversed.toList();
      setState(() {
        loadState = false;
        searchState = false;
      });
    }
  }

  bool containsLetter(String text) {
    for (int i = 0; i < text.length; i++) {
      if (text[i].toUpperCase() != text[i].toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 40, 40, 42),
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
              "| Arama",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: ScrollConfiguration(
        behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: loadState
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
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 5, left: 10, right: 10, bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: usernameController,
                          maxLength: 20,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.grey,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) => searchUser(value),
                          maxLines: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(
                                RegExp(r'[^\w\s\.]')),
                          ],
                          onChanged: (text) {
                            List<String> words = text.split(' ');
                            String username = words
                                .where((word) => word.isNotEmpty)
                                .join(' ');
                            text = username;
                            usernameController.text = text.toLowerCase();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Ara..',
                            hintStyle: TextStyle(
                                color: Color.fromARGB(255, 123, 123, 123)),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: Color.fromARGB(255, 54, 54, 54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0.0,
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            counterText: "",
                          ),
                        ),
                      ),
                    ),
                    if (searchState && dataList.isEmpty)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 16),
                            Text(
                              "Kullanıcı Bulunamadı.",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    else
                      buildRecentWidgets(),
                  ],
                ),
        ),
      ),
    );
  }

  ImageProvider getProfileImage(dynamic blobData) {
    if (blobData is Blob) {
      Uint8List uint8listData = blobData.bytes;
      String base64String = base64.encode(uint8listData);
      return MemoryImage(Uint8List.fromList(base64.decode(base64String)));
    } else {
      return const AssetImage('assets/images/default.png');
    }
  }

  Widget buildRecentWidgets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dataList.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            child: Text(
              (!searchState) ? 'Geçmiş' : 'Sonuçlar',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        const SizedBox(height: 5),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: dataList.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "/otherProfile",
                      arguments: dataList[index].documentId);
                  bool state = reserve.any((item) =>
                      item.documentId == dataList[index].documentId.toString());
                  searchUserDatas user = searchUserDatas(
                      username: dataList[index].username,
                      pp: dataList[index].pp,
                      documentId: dataList[index].documentId,
                      about: dataList[index].about);
                  localRecents().insertUser(user);
                  if (!state) {
                    reserve.add(user);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(2.0),
                  color: const Color.fromARGB(255, 54, 54, 54),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: getProfileImage(dataList[index].pp),
                    ),
                    title: Row(children: [
                      Text(
                        dataList[index].username,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dataList[index].username == "mustafawiped")
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
                    ]),
                    subtitle: Text(
                      dataList[index].about,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: (!searchState)
                        ? TextButton(
                            onPressed: () {
                              localRecents()
                                  .deleteUser(dataList[index].documentId);
                              reserve.removeAt(index);
                              dataList.removeAt(index);
                              setState(() {});
                            },
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 54, 54, 54),
                              minimumSize: const Size(30, 10),
                            ),
                            child: const Text(
                              'X',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
