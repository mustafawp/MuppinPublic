import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: camel_case_types
class aboutScreen extends StatefulWidget {
  const aboutScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _aboutScreenState createState() => _aboutScreenState();
}

// ignore: camel_case_types
class _aboutScreenState extends State<aboutScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                "| Hakkımızda",
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                buildSection(
                    "Muppin Nedir?",
                    "Muppin, temel amacı insanların birbiriyle rahatça konuşmasını amaçlayan bir canlı sohbet uygulamasıdır. Ayrıca yeni insanlar ile tanışmanızı sağlamayı da amaçlar. Bir çok canlı sohbet uygulamasına kıyasla Muppin, sizlerin konuşma geçmişini ya da kişisel verilerinizi kimse ile paylaşmaz.",
                    false),
                buildSection(
                    "Vizyonumuz",
                    "Vizyonumuz, herkes tarafından güvenilen, rahatça sohbet edilen, hatasız ve güçlü bir canlı sohbet platformu kurmaktır. Ayriyetten bu platformun içerisinde bir çok yeni arkadaşlık, dostluk, kardeşlik ilişkileri kurulabilen bir platform tasarlamaktır.",
                    false),
                buildSection(
                    "Ekibimiz",
                    "Muppin ekibi, yüzlerce insandan oluşmamaktadır. Ekibimiz 2 kişilik bir ekiptir. Muppin tamamiyle 2 kişilik bir ekip tarafından herhangi bir destek ya da yardım almadan geliştirilmiştir ve geliştirilmeye devam etmektedir. Uygulamamızın kurucusu Mustafa Gür 'dür.",
                    false),
                buildSection(
                    "Neden Bize Güvenmelisiniz?",
                    "Muppin'in temelde geliştirilme amacı hem insanlara güvenli bir ortam sunmaktır, hem de Geliştirici Ekibi'nin tecrübe kazanmasıdır. Kısacası herhangi bir ticari amaç için geliştirilmiş bir mobil uygulama değildir. Bu açıklama yeterli olmuştur umarım.",
                    false),
                buildSection(
                    "İletişim",
                    "Bizler ile iletişime geçmek için eposta adresimize eposta atabilir ya da bizlere destek olup, not olarak iletişim adresinizi bırakabilirsiniz. \nEposta: mustafawiped@gmail.com ",
                    false),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Geliştirme Sürecine Destek",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Muppin yalnızca iki öğrenci tarafından geliştirilmekte. Uygulamamızı beğendiyseniz ve daha hızlı geliştirilmesini istiyorsanız, bize destek olun.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Uri url = Uri.parse(
                              "https://www.buymeacoffee.com/mustafawiped");
                          launchUrl(url);
                        },
                        // ignore: sort_child_properties_last
                        child: const Text("Destek Ol"),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.green),
                          fixedSize: MaterialStateProperty.all(const Size(
                              170, 25)), // Genişlik ve yükseklik ayarları
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          AwesomeDialog(
                            context: context,
                            dialogBackgroundColor:
                                const Color.fromARGB(255, 32, 32, 32),
                            btnOkColor: Colors.red,
                            btnCancelColor: Colors.green,
                            titleTextStyle:
                                const TextStyle(color: Colors.white),
                            descTextStyle: const TextStyle(color: Colors.white),
                            dialogType: DialogType.question,
                            animType: AnimType.topSlide,
                            btnOkText: "Hayır",
                            btnCancelText: "Evet",
                            title: 'Henüz Katkıda bulunan biri yok..',
                            desc:
                                'Şuanlık bize destek olan biri yok gibi gözüküyor. İlk olmak ister misin?',
                            btnOkOnPress: () {},
                            btnCancelOnPress: () {
                              Uri url = Uri.parse(
                                  "https://www.buymeacoffee.com/mustafawiped");
                              launchUrl(url);
                            },
                          ).show();
                        },
                        // ignore: sort_child_properties_last
                        child: const Text("Katkıda Bulunanlar"),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                          fixedSize: MaterialStateProperty.all(const Size(
                              170, 25)), // Genişlik ve yükseklik ayarları
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSection(String title, String content, bool isLastSection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        if (!isLastSection) // Son bölüm değilse çizgiyi ekle
          const Divider(
            color: Color.fromARGB(154, 106, 94, 112),
            thickness: 5.0,
            height: 20.0,
          ),
      ],
    );
  }
}
