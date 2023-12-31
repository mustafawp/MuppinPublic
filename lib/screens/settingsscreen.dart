import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:muppin_app/database/local/localdb.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:muppin_app/transactions/shareds.dart';

// ignore: use_key_in_widget_constructors, camel_case_types
class settingsScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _settingsScreenState createState() => _settingsScreenState();
}

const kprimaryColor = Color.fromARGB(255, 255, 255, 255);
const ksecondryColor = Color.fromARGB(255, 255, 255, 255);
const ksecondryLightColor = Color.fromARGB(154, 73, 47, 85);
const klightContentColor = Color.fromARGB(154, 73, 47, 85);

const double kbigFontSize = 25;
const double knormalFontSize = 18;
const double ksmallFontSize = 15;

// ignore: camel_case_types
class _settingsScreenState extends State<settingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1), () {
      initConfigures();
    });
  }

  bool isLoading = true;

  List datas = [];
  String username = "";
  String mail = "";
  dynamic profilePF = const AssetImage('assets/images/default.png');

  void initConfigures() async {
    String docId = await Shareds.sharedCek("docId");
    localDatabase db = localDatabase();
    dynamic datas =
        await db.getUserDatas(docId, "accName, profilePhoto, email");
    if (datas != null) {
      Map<String, dynamic> dataFields = datas;
      username = dataFields["accName"] ?? "";
      dynamic profilePhoto = dataFields["profilePhoto"];
      if (profilePhoto is Uint8List && profilePhoto.isNotEmpty) {
        String base64String = base64.encode(profilePhoto);
        ImageProvider imageProvider = MemoryImage(base64.decode(base64String));
        profilePF = imageProvider;
      }
      mail = dataFields["email"] ?? "";
      setState(() {
        isLoading = false;
      });
    }
  }

  String maskEmail(String email) {
    List<String> parts = email.split("@");
    if (parts.length != 2) {
      return email;
    }
    String maskedPart =
        "${parts[0].substring(0, 2)}${"*" * (parts[0].length - 1)}@${parts[1]}";

    return maskedPart;
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
              "| Ayarlar",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 16),
                  Text(
                    "Yükleniyor",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 15),
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: ScrollConfiguration(
                behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: profilePF,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontSize: kbigFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: kprimaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    maskEmail(mail),
                                    style: TextStyle(
                                      fontSize: ksmallFontSize,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        Column(
                          children: List.generate(
                            settings.length,
                            (index) => SettingTile(setting: settings[index]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: List.generate(
                            settings2.length,
                            (index) => SettingTile(setting: settings2[index]),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SupportCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class Setting {
  final String title;
  final String route;
  final IconData icon;
  final Color color;

  Setting({
    required this.title,
    required this.route,
    required this.icon,
    required this.color,
  });
}

final List<Setting> settings = [
  Setting(
    title: "Hesap Ayarları",
    route: "/accountsettings",
    icon: CupertinoIcons.person_fill,
    color: Colors.white,
  ),
  Setting(
    title: "Uygulama Ayarları",
    route: "/",
    icon: Icons.settings,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Beğenilen Hikayeler",
    route: "/",
    icon: CupertinoIcons.heart_fill,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Spotify Hesabını Bağla",
    route: "/",
    icon: Icons.music_note,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Onaylama İste",
    route: "/",
    icon: Icons.verified,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Engellenen Kullanıcılar",
    route: "/",
    icon: Icons.block,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Güvenlik Kayıtları",
    route: "/",
    icon: Icons.security,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
];

final List<Setting> settings2 = [
  Setting(
    title: "Hakkımızda",
    route: "/about",
    icon: CupertinoIcons.person_3_fill,
    color: Colors.white,
  ),
  Setting(
    title: "Güncellemeler",
    route: "/",
    icon: CupertinoIcons.refresh,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Kullanıcı Sözleşmesi",
    route: "/",
    icon: CupertinoIcons.doc_fill,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Dil Tercihi",
    route: "/",
    icon: Icons.language,
    color: const Color.fromARGB(255, 108, 108, 108),
  ),
  Setting(
    title: "Çıkış Yap",
    route: "/logout",
    icon: CupertinoIcons.gobackward,
    color: Colors.white,
  ),
];

// SettingTile sınıfına bir işlev ekleyin
class SettingTile extends StatelessWidget {
  final Setting setting;

  const SettingTile({
    super.key,
    required this.setting,
  });

  void handleSettingTap(BuildContext context) {
    switch (setting.route) {
      case "/accountsettings":
        Navigator.pushNamed(
          context,
          setting.route,
          arguments: "Hesap Ayarları",
        );
        break;
      case "/logout":
        AwesomeDialog(
          context: context,
          dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
          btnOkColor: Colors.red,
          btnCancelColor: Colors.blue,
          titleTextStyle: const TextStyle(color: Colors.white),
          descTextStyle: const TextStyle(color: Colors.white),
          dialogType: DialogType.question,
          animType: AnimType.topSlide,
          btnOkText: "Çıkış Yap",
          btnCancelText: "Vazgeç",
          title: 'Hesabından Çıkış Yapıyorsun..',
          desc:
              'Yalnızca yanlışlıkla tıklamadığını teyit etmek istiyoruz. Eminsin değil mi?',
          btnOkOnPress: () {
            Navigator.pop(context, "logout");
          },
          btnCancelOnPress: () {},
        ).show();
        break;
      case "/about":
        Navigator.pushNamed(context, "/about");
        break;
      case "/":
        AwesomeDialog(
          context: context,
          dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
          btnOkColor: const Color.fromARGB(154, 73, 47, 85),
          titleTextStyle: const TextStyle(color: Colors.white),
          descTextStyle: const TextStyle(color: Colors.white),
          dialogType: DialogType.info,
          animType: AnimType.topSlide,
          title: 'Bu Ayar inaktif.',
          desc:
              'Beta sürecinde bir çok ayar inaktif. Güncellemeler size otomatik mesaj olarak gelecektir.',
          btnOkOnPress: () {},
        ).show();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => handleSettingTap(context),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              color: klightContentColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(setting.icon, color: setting.color),
          ),
          const SizedBox(width: 10),
          Text(
            setting.title,
            style: TextStyle(
              color: setting.color,
              fontSize: ksmallFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Icon(
            CupertinoIcons.chevron_forward,
            color: setting.color,
          ),
        ],
      ),
    );
  }
}

class SupportCard extends StatelessWidget {
  const SupportCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        color: ksecondryLightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.support_agent,
            size: 50,
            color: ksecondryColor,
          ),
          Text(
            "Geri Bildirim veya Yardım Talebi Gönder",
            style: TextStyle(
              fontSize: ksmallFontSize,
              color: ksecondryColor,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}
