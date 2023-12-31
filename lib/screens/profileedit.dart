// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:muppin_app/database/local/localdb.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/transactions/shareds.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

// ignore: use_key_in_widget_constructors, camel_case_types
class profileEdit extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _profileEditState createState() => _profileEditState();
}

// ignore: camel_case_types
class _profileEditState extends State<profileEdit> {
  String documentId = "";
  String defAccname = "";

  DateTime parseDate(String dateText) {
    final List<String> parts = dateText.split(' ');
    if (parts.length != 3) {
      // Geçersiz format
      return DateTime.now();
    }

    final int day = int.tryParse(parts[0]) ?? 1; // Gün
    final int year = int.tryParse(parts[2]) ?? DateTime.now().year;
    final Map<String, int> monthMap = {
      'Ocak': 1,
      'Şubat': 2,
      'Mart': 3,
      'Nisan': 4,
      'Mayıs': 5,
      'Haziran': 6,
      'Temmuz': 7,
      'Ağustos': 8,
      'Eylül': 9,
      'Ekim': 10,
      'Kasım': 11,
      'Aralık': 12,
    };
    final int month = monthMap[parts[1]] ?? 1;
    return DateTime(year, month, day);
  }

  bool _loadState = true;
  String _loadText = "Yükleniyor";

  bool isUserNameErrorState = false;
  String isUserNameErrorText = "Hata! Tekrar dene.";

  bool isAboutErrorState = false;
  String isAboutErrorText = "Hata! Tekrar dene.";

  bool isInstagramState = false;
  String isInstagramText = "Hata! Tekrar dene.";

  bool isTwitterState = false;
  String isTwitterText = "Hata! Tekrar dene.";

  bool isDiscordState = false;
  String isDiscordText = "Hata! Tekrar dene.";

  bool isYoutubeState = false;
  String isYoutubeText = "Hata! Tekrar dene.";

  bool _showAdditionalLinks = false;
  bool iVisibleOther = true;

  String _aboutMe = "Hata! Profiliniz yüklenemedi. Daha sonra tekrar deneyin.";
  String _gender = "";
  DateTime _birthDate = DateTime.now();
  String _formattedDate = "";
  String _pronouns = "";
  ImageProvider<Object> _profileImage =
      const AssetImage('assets/images/default.png');

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    var pickedFile = await picker.pickImage(source: ImageSource.gallery);
    try {
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 20, // Sıkıştırma kalitesi ayarı (0-100 arasında)
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Muppin | Resim Düzenleyici',
                toolbarColor: const Color.fromARGB(255, 32, 36, 47),
                toolbarWidgetColor: const Color.fromARGB(255, 220, 220, 220),
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false),
          ],
        );
        if (croppedFile != null) {
          File file = File(croppedFile.path);
          final image = img.decodeImage(file.readAsBytesSync());
          final resizedImage = img.copyResize(image!, width: 300, height: 300);
          String base64Image = base64Encode(img.encodeJpg(resizedImage));

          setState(() {
            _profileImage = MemoryImage(base64Decode(base64Image));
          });
        } else {
          Fluttertoast.showToast(
              msg:
                  "Beklenmeyen bir hata çıktı. İşlem başarısız. Hata Kodu: PP");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Beklenmeyen bir hata çıktı. Daha sonra tekrar dene.");
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      initConfigures();
    });
  }

  void initConfigures() async {
    // ignore: await_only_futures
    String docId = await Shareds.sharedCek("docId");
    localDatabase db = localDatabase();
    dynamic datas = await db.getUserDatas(docId,
        "instagram, twitter, discord, youtube, aboutText, gender, birthday, docId, pronouns, profilePhoto, accName");
    if (datas != null) {
      Map<String, dynamic> dataFields = datas;
      Map<String, dynamic> userSocials = {};
      String instagram = dataFields["instagram"] ?? "";
      String twitter = dataFields["twitter"] ?? "";
      String discord = dataFields["discord"] ?? "";
      String youtube = dataFields["youtube"] ?? "";
      if (instagram != "") userSocials["instagram"] = instagram;
      if (twitter != "") userSocials["twitter"] = twitter;
      if (discord != "") userSocials["discord"] = discord;
      if (youtube != "") userSocials["youtube"] = youtube;
      try {
        _aboutMe = (dataFields["aboutText"] != "")
            ? dataFields["aboutText"]
            : "Hakkımda Yüklenemedi.";
        _gender = (dataFields["gender"].toString() != "")
            ? dataFields["gender"]
            : _gender;
        _birthDate = (dataFields["birthday"].toString() != "")
            ? parseDate(dataFields["birthday"].toString())
            : _birthDate;
        _formattedDate = (dataFields["birthday"].toString() != "")
            ? dataFields["birthday"].toString()
            : "";

        _pronouns = (dataFields["pronouns"].toString() != "")
            ? dataFields["pronouns"].toString()
            : _pronouns;
        dynamic profilePhoto = dataFields["profilePhoto"];
        if (profilePhoto is Uint8List && profilePhoto.isNotEmpty) {
          String base64String = base64.encode(profilePhoto);
          ImageProvider imageProvider =
              MemoryImage(base64.decode(base64String));
          _profileImage = imageProvider;
        }
        setState(() {});
        userSocials.forEach((key, value) {
          switch (key) {
            case "instagram":
              instagramController.text = value;
              break;
            case "twitter":
              twitterController.text = value;
              break;
            case "discord":
              _showAdditionalLinks = true;
              discordController.text = value;
              break;
            case "youtube":
              _showAdditionalLinks = true;
              youtubeController.text = value;
              break;
          }
        });
        documentId = dataFields["docId"].toString();
        defAccname = dataFields["accName"];
      } catch (e) {
        if (kDebugMode) {
          print("Profile Error: $e");
        }
      }

      setState(() {
        usernameController.text = defAccname;
        _loadState = false;
      });
    } else {
      setState(() {
        _loadText = "Hata!\nDaha sonra tekrar dene";
      });
    }
  }

  bool containsInvalidCharacters(String text) {
    final validPattern = RegExp(r'^[a-z-0-9_\s]+$');
    if (!validPattern.hasMatch(text)) {
      return true;
    }
    return false;
  }

  bool instagramAccountNameControl(String text) {
    final validPattern = RegExp(r'^[a-z0-9_\s.]+$');
    if (!validPattern.hasMatch(text)) {
      return true;
    }
    return false;
  }

  bool discordLinkControl(String text) {
    final validPattern = RegExp(r'^[a-zA-Z0-9]+$');
    return !validPattern.hasMatch(text);
  }

  bool youtubeAccountNameControl(String text) {
    final validPattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
    return !validPattern.hasMatch(text);
  }

  bool buttonLoading = false;

  bool containsLetter(String text) {
    for (int i = 0; i < text.length; i++) {
      if (text[i].toUpperCase() != text[i].toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  void updateProfileMethod() async {
    // hata durumu kontrol
    if (isUserNameErrorState ||
        isAboutErrorState ||
        isInstagramState ||
        isTwitterState ||
        isDiscordState ||
        isYoutubeState) return;

    setState(() {
      buttonLoading = true;
    });

    String username = usernameController.text; // tüm verileri almak
    String about = _aboutMe;
    String gender = _gender;
    String date = _formattedDate;
    String pronouns = _pronouns;
    String instagram = instagramController.text;
    String twitter = twitterController.text;
    String discord = discordController.text;
    String youtube = youtubeController.text;

    // kullanıcıadı kontrol
    if (username.length < 4 || username.length > 20) {
      isUserNameErrorText =
          "Kullanıcı adı en az 4, en fazla 20 karakter olabilir.";
      setState(() {
        isUserNameErrorState = true;
        buttonLoading = false;
      });
      return;
    }

    if (!containsLetter(username)) {
      isUserNameErrorText = "Kullanıcı adı en az 1 harf içermelidir.";
      setState(() {
        isUserNameErrorState = true;
        buttonLoading = false;
      });
      return;
    }

    if (!isValidUsername(username)) {
      isUserNameErrorText =
          "Kullanıcı adı . veya _ ile başlayamaz. Yan yana da olamaz.";
      setState(() {
        isUserNameErrorState = true;
        buttonLoading = false;
      });
      return;
    }

    Map<String, dynamic> userSocials = {}; // sosyal medya hesapları kontrolü
    if (instagram.isNotEmpty && instagram.length >= 5) {
      userSocials["instagram"] = instagram;
    }
    if (twitter.isNotEmpty && twitter.length >= 5) {
      userSocials["twitter"] = twitter;
    }
    if (discord.isNotEmpty && discord.length >= 7) {
      userSocials["discord"] = discord;
    }
    if (youtube.isNotEmpty && youtube.length >= 5) {
      userSocials["youtube"] = youtube;
    }

    dynamic profilePhoto = "-"; // Resim verisi alma
    if (_profileImage.runtimeType == FileImage) {
      File file = (_profileImage as FileImage).file;
      Uint8List bytes = await file.readAsBytes();
      profilePhoto = Blob(bytes);
    } else if (_profileImage.runtimeType == MemoryImage) {
      MemoryImage memoryImage = _profileImage as MemoryImage;
      Uint8List bytes = memoryImage.bytes;
      profilePhoto = Blob(bytes);
    } else {
      profilePhoto = "-";
    }

    database db = database(); // Veritabanı bağlantısı
    Future<bool> state = db.getUsersByField("username", username);

    state.then((value) {
      if (value && defAccname != username) {
        isUserNameErrorText = "Bu kullanıcı adı zaten kullanılmaktadır.";
        setState(() {
          isUserNameErrorState = true;
          buttonLoading = false;
        });
      } else {
        Map<String, dynamic> fields = {
          "username": username,
          "about": about,
          "gender": gender,
          "birthday": date,
          "pronouns": pronouns,
          "socials": userSocials,
          "pp": profilePhoto,
        };
        Future<bool> state = db.updateDatas(fields, documentId);
        state.then((value) async {
          if (value) {
            localDatabase localDb = localDatabase();
            Map<String, dynamic> newDatas = {};
            if (profilePhoto is Blob) {
              Blob blobData = profilePhoto;
              Uint8List uint8listData = blobData.bytes;
              newDatas["profilePhoto"] = uint8listData;
            } else {
              newDatas["profilePhoto"] = "-";
            }
            newDatas["accName"] = username;
            newDatas["aboutText"] = about;
            newDatas["gender"] = gender;
            newDatas["birthday"] = date;
            newDatas["pronouns"] = pronouns;
            if (userSocials["instagram"] != null ||
                userSocials["instagram"] != "")
              newDatas["instagram"] = userSocials["instagram"];
            if (userSocials["twitter"] != null || userSocials["twitter"] != "")
              newDatas["twitter"] = userSocials["twitter"];
            if (userSocials["discord"] != null || userSocials["discord"] != "")
              newDatas["discord"] = userSocials["discord"];
            if (userSocials["youtube"] != null || userSocials["youtube"] != "")
              newDatas["youtube"] = userSocials["youtube"];
            await localDb.updateOtherMethod(documentId, newDatas);
            if (profilePhoto is Blob) newDatas["profilePhoto"] = _profileImage;
            newDatas["socials"] = userSocials;
            // ignore: use_build_context_synchronously
            Navigator.pop(context, newDatas);
          } else {
            AwesomeDialog(
              context: context,
              dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
              btnOkColor: const Color.fromARGB(154, 73, 47, 85),
              titleTextStyle: const TextStyle(color: Colors.white),
              descTextStyle: const TextStyle(color: Colors.white),
              dialogType: DialogType.error,
              animType: AnimType.topSlide,
              title: 'İşlem Başarısız.',
              desc: 'Bir şeyler ters gitti. Daha sonra tekrar dene.',
              btnOkOnPress: () {},
            ).show();
          }
        });
      }
    });
  }

  bool isValidUsername(String username) {
    if (username.isEmpty) {
      return false;
    }

    if (username.startsWith('.') ||
        username.endsWith('.') ||
        username.contains('..')) {
      return false;
    }

    if (username.startsWith('_') ||
        username.endsWith('_') ||
        username.contains('__')) {
      return false;
    }

    if (username.contains('._') ||
        username.contains('_.') ||
        username.contains('_.')) {
      return false;
    }

    return true;
  }

  TextEditingController usernameController = TextEditingController();
  TextEditingController instagramController = TextEditingController();
  TextEditingController twitterController = TextEditingController();
  TextEditingController discordController = TextEditingController();
  TextEditingController youtubeController = TextEditingController();

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
              "| Profil Düzenle",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      body: _loadState == true
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _loadText,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ],
              ),
            )
          : ScrollConfiguration(
              behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: Stack(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _profileImage,
                          ),
                          const Positioned(
                            top: 90,
                            bottom: 0,
                            right: 10,
                            child:
                                Icon(Icons.change_circle, color: Colors.white),
                          ),
                          Positioned(
                            top: 90,
                            bottom: 0,
                            right: 90,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _profileImage = const NetworkImage(
                                      'https://www.hotelbooqi.com/wp-content/uploads/2021/12/128-1280406_view-user-icon-png-user-circle-icon-png.png');
                                });
                              },
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      maxLength: 20,
                      decoration: InputDecoration(
                        labelText: "Kullanıcı Adı",
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 54, 54, 54),
                        hintStyle: const TextStyle(color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        counterText: "",
                        errorText:
                            isUserNameErrorState ? isUserNameErrorText : null,
                      ),
                      onChanged: (text) {
                        List<String> words = text.split(' ');
                        String username =
                            words.where((word) => word.isNotEmpty).join(' ');
                        text = username;
                        usernameController.text = text.toLowerCase();
                        if (containsInvalidCharacters(
                            usernameController.text)) {
                          isUserNameErrorText =
                              "Yalnızca a-z, 0-9 ve _ Kullanılabilir.";
                          setState(() {
                            isUserNameErrorState = true;
                          });
                          return;
                        }
                        if (isUserNameErrorState) {
                          setState(() {
                            isUserNameErrorState = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      initialValue: _aboutMe,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: "Hakkında",
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 54, 54, 54),
                        hintStyle: const TextStyle(color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        counterText: "",
                        errorText: isAboutErrorState ? isAboutErrorText : null,
                      ),
                      onChanged: (value) {
                        if (value.length < 5) {
                          setState(() {
                            isAboutErrorState = true;
                            isAboutErrorText =
                                "Hakkında kısmı minimum 5 maksimum 120 karakter olmalı.";
                          });
                        } else if (isAboutErrorState) {
                          setState(() {
                            isAboutErrorState = false;
                          });
                        }
                        setState(() {
                          _aboutMe = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 54, 54, 54),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Stack(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: iVisibleOther ? 0 : 60,
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Radio(
                                      value: "Erkek",
                                      groupValue: _gender,
                                      fillColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.selected)) {
                                            return Colors.purple;
                                          }
                                          return Colors.grey;
                                        },
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _gender = value!;
                                        });
                                      },
                                    ),
                                    const Text(
                                      'Erkek',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: iVisibleOther ? 0 : 30,
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Radio(
                                      value: "Kadın",
                                      groupValue: _gender,
                                      fillColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.selected)) {
                                            return Colors.purple;
                                          }
                                          return Colors.grey;
                                        },
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _gender = value!;
                                        });
                                      },
                                    ),
                                    const Text(
                                      'Kadın',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: iVisibleOther
                                    ? Row(
                                        children: <Widget>[
                                          Radio(
                                            value: "Diğer",
                                            fillColor: MaterialStateProperty
                                                .resolveWith<Color>(
                                              (Set<MaterialState> states) {
                                                if (states.contains(
                                                    MaterialState.selected)) {
                                                  return Colors.purple;
                                                }
                                                return Colors.grey;
                                              },
                                            ),
                                            groupValue: _gender,
                                            onChanged: (value) {
                                              setState(() {
                                                iVisibleOther = false;
                                                _gender = "Kadın";
                                                Uri url = Uri.parse(
                                                    "https://www.youtube.com/watch?v=dQw4w9WgXcQ");
                                                launchUrl(url);
                                              });
                                            },
                                          ),
                                          const Text(
                                            'Diğer',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                          Transform(
                            transform:
                                Matrix4.translationValues(15.0, -8.0, 0.0),
                            child: const Text(
                              'Cinsiyet',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Doğum Tarihi",
                              labelStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 54, 54, 54),
                              hintStyle: const TextStyle(color: Colors.grey),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            readOnly: true,
                            onTap: () {
                              showDatePicker(
                                context: context,
                                initialDate: _birthDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      primaryColor:
                                          const Color.fromARGB(154, 73, 47, 85),
                                      cardColor:
                                          const Color.fromARGB(154, 73, 47, 85),
                                      colorScheme: const ColorScheme.light(
                                        primary:
                                            Color.fromARGB(154, 73, 47, 85),
                                        onPrimary: Colors.white,
                                        surface:
                                            Color.fromARGB(154, 255, 255, 255),
                                        onSurface: Colors.white,
                                      ),
                                      dialogBackgroundColor:
                                          const Color.fromARGB(
                                              255, 104, 82, 114),
                                    ),
                                    child: child!,
                                  );
                                },
                              ).then((date) {
                                if (date != null) {
                                  final Map<String, String> months = {
                                    "January": "Ocak",
                                    "February": "Şubat",
                                    "March": "Mart",
                                    "April": "Nisan",
                                    "May": "Mayıs",
                                    "June": "Haziran",
                                    "July": "Temmuz",
                                    "August": "Ağustos",
                                    "September": "Eylül",
                                    "October": "Ekim",
                                    "November": "Kasım",
                                    "December": "Aralık"
                                  };
                                  setState(() {
                                    _birthDate = date;
                                    _formattedDate =
                                        DateFormat("dd MMMM yyyy").format(date);
                                    months.forEach((ingilizce, turkce) {
                                      _formattedDate = _formattedDate
                                          .replaceAll(ingilizce, turkce);
                                    });
                                  });
                                }
                              });
                            },
                            controller:
                                TextEditingController(text: _formattedDate),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: TextFormField(
                            initialValue: _pronouns,
                            maxLength: 20,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Hitaplar",
                              labelStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 54, 54, 54),
                              hintStyle: const TextStyle(color: Colors.grey),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              counterText: "",
                            ),
                            onChanged: (value) {
                              setState(() {
                                _pronouns = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: instagramController,
                      maxLength: 30,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixText: "@",
                        labelText: "Instagram Hesabın",
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 54, 54, 54),
                        hintStyle: const TextStyle(color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        counterText: "",
                        errorText: isInstagramState ? isInstagramText : null,
                      ),
                      onChanged: (text) {
                        List<String> words = text.split(' ');
                        String username =
                            words.where((word) => word.isNotEmpty).join(' ');
                        text = username;
                        instagramController.text = text.toLowerCase();
                        if (instagramAccountNameControl(text) &&
                            text.isNotEmpty) {
                          isInstagramText =
                              "Yalnızca a-z, 0-9 ve _ Kullanılabilir.";
                          setState(() {
                            isInstagramState = true;
                          });
                          return;
                        }
                        if (isInstagramState) {
                          setState(() {
                            isInstagramState = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: twitterController,
                      maxLength: 15,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixText: "@",
                        labelText: "X (Twitter) Hesabın",
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 54, 54, 54),
                        hintStyle: const TextStyle(color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        counterText: "",
                        errorText: isTwitterState ? isTwitterText : null,
                      ),
                      onChanged: (text) {
                        List<String> words = text.split(' ');
                        String username =
                            words.where((word) => word.isNotEmpty).join(' ');
                        text = username;
                        twitterController.text = text.toLowerCase();
                        if (containsInvalidCharacters(text) &&
                            text.isNotEmpty) {
                          isTwitterText =
                              "Yalnızca a-z, 0-9 ve _ Kullanılabilir.";
                          setState(() {
                            isTwitterState = true;
                          });
                          return;
                        }
                        if (isTwitterState) {
                          setState(() {
                            isTwitterState = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAdditionalLinks = !_showAdditionalLinks;
                        });
                      },
                      child: Text(
                        _showAdditionalLinks ? "Vazgeç.." : "Daha fazla ekle..",
                        style: const TextStyle(
                          color: Colors.blue, // veya istediğiniz renk
                        ),
                      ),
                    ),
                    if (_showAdditionalLinks)
                      Column(
                        children: [
                          const SizedBox(height: 8.0),
                          TextFormField(
                            controller: discordController,
                            maxLength: 10,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Discord Sunucu Linki",
                              prefixText: "discord.gg/",
                              labelStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 54, 54, 54),
                              hintStyle: const TextStyle(color: Colors.grey),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              counterText: "",
                              errorText: isDiscordState ? isDiscordText : null,
                            ),
                            onChanged: (text) {
                              List<String> words = text.split(' ');
                              String username = words
                                  .where((word) => word.isNotEmpty)
                                  .join(' ');
                              discordController.text = username;
                              if (discordLinkControl(discordController.text) &&
                                  discordController.text.isNotEmpty) {
                                isDiscordText =
                                    "Discord Bağlantısında yalnızca harf ve sayı olabilir.";
                                setState(() {
                                  isDiscordState = true;
                                });
                                return;
                              }
                              if (isDiscordState) {
                                setState(() {
                                  isDiscordState = false;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8.0),
                          TextFormField(
                            controller: youtubeController,
                            maxLength: 30,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "YouTube Bağlantısı",
                              prefixText: "youtube.com/@",
                              labelStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 54, 54, 54),
                              hintStyle: const TextStyle(color: Colors.grey),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              counterText: "",
                              errorText: isYoutubeState ? isYoutubeText : null,
                            ),
                            onChanged: (text) {
                              List<String> words = text.split(' ');
                              String username = words
                                  .where((word) => word.isNotEmpty)
                                  .join(' ');
                              text = username;
                              if (youtubeAccountNameControl(text) &&
                                  text.isNotEmpty) {
                                isYoutubeText =
                                    "Yalnızca a-z, 0-9 ve _ Kullanılabilir.";
                                setState(() {
                                  isYoutubeState = true;
                                });
                                return;
                              }
                              if (isYoutubeState) {
                                setState(() {
                                  isYoutubeState = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 16.0),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: ElevatedButton(
                        onPressed: updateProfileMethod,
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
                        child: buttonLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 255, 255, 255)),
                                ),
                              )
                            : const Text(
                                "Değişiklikleri Kaydet",
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
    );
  }
}
