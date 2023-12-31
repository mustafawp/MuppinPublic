import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:muppin_app/database/local/localdb.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/email.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/transactions/shareds.dart';

// ignore: camel_case_types, use_key_in_widget_constructors
class accountSettings extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<accountSettings> {
  String header = "Unknown";

  String mail = "", pass = "", phone = "";
  String docId = "";

  bool loadScreenState = true;
  String loadScreenText = "Yükleniyor..";

  String mailEP = "1";
  String phoneEP = "1";
  String accdelEP = "1";

  bool mailButtonLoading = false;
  bool passButtonLoading = false;
  bool phoneButtonLoading = false;
  bool deleteButtonLoading = false;

  bool mailErrorState = false;
  String mailErrorText = "Hata! Lütfen tekrar dene.";

  bool passErrorState = false;
  String passErrorText = "Hata! Lütfen tekrar dene.";

  bool pass2ErrorState = false;
  String pass2ErrorText = "Hata! Lütfen tekrar dene.";

  bool phoneErrorState = false;
  String phoneErrorText = "Hata! Lütfen tekrar dene.";

  bool deleteErrorState = false;
  String deleteErrorText = "Hata! Lütfen tekrar dene.";

  String newMail = "";

  TextEditingController mailTextController = TextEditingController();
  TextEditingController oldPassTextController = TextEditingController();
  TextEditingController newPassTextController = TextEditingController();
  TextEditingController phoneTextController = TextEditingController();
  TextEditingController deleteTextController = TextEditingController();

  void emailButtonClick() async {
    setState(() {
      mailButtonLoading = true;
    });

    if (mailEP == "1") {
      if (mail.isNotEmpty && mail.contains("@") && mail.contains(".com")) {
        await emailPass().verifyEmail(mail);
        setState(() {
          mailEP = "2";
          mailButtonLoading = false;
        });
      } else {
        Fluttertoast.showToast(
            msg:
                "Bir hata ile karşılaştınız. Lütfen daha sonra tekrar deneyin.");
      }
    } else if (mailEP == "2") {
      String code = mailTextController.text;
      bool control = emailPass().tryVerifyCode(int.parse(code));
      if (control) {
        setState(() {
          FocusScope.of(context).unfocus();
          mailTextController.text = "";
          mailEP = "3";
          mailButtonLoading = false;
        });
      } else {
        setState(() {
          mailErrorState = true;
          mailErrorText = "Doğrulama kodu hatalı!";
          mailButtonLoading = false;
        });
      }
    } else if (mailEP == "3") {
      String email = mailTextController.text;
      if (email == mail) {
        setState(() {
          mailErrorState = true;
          mailErrorText = "Zaten bu epostayı kullanıyorsunuz.";
          mailButtonLoading = false;
        });
        return;
      }
      if (email.contains("@gmail.com") && email != "@gmail.com" ||
          email.contains("@hotmail.com") && email != "@hotmail.com" ||
          email.contains("@outlook.com") && email != "@outlook.com" ||
          email.contains("@yahoo.com") && email != "@yahoo.com" ||
          email.contains("@yandex.com") && email != "@yandex.com") {
        database db = database();
        bool state = await db.getUsersByField("email", email);
        if (state) {
          setState(() {
            mailErrorState = true;
            mailErrorText = "Bu epostayı başka bir kullanıcı kullanmakta.";
            mailButtonLoading = false;
          });
          return;
        }
        await emailPass().verifyEmail(email);
        setState(() {
          FocusScope.of(context).unfocus();
          mailTextController.text = "";
          mailEP = "4";
          mailButtonLoading = false;
        });
        newMail = email;
      } else {
        setState(() {
          mailErrorState = true;
          mailErrorText = "Lütfen geçerli bir eposta adresi gir.";
          mailButtonLoading = false;
        });
      }
    } else if (mailEP == "4") {
      String code = mailTextController.text;
      bool control = emailPass().tryVerifyCode(int.parse(code));
      if (control && newMail.isNotEmpty) {
        Map<String, dynamic> fields = {"email": newMail};
        database db = database();
        Future<bool> state = db.updateDatas(fields, docId);
        mailEP = "1";
        setState(() {
          mailTextController.text = "";
          mailButtonLoading = false;
        });
        state.then((value) async {
          if (value) {
            AwesomeDialog(
              context: context,
              dismissOnTouchOutside: false,
              dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
              btnOkColor: const Color.fromARGB(154, 73, 47, 85),
              titleTextStyle: const TextStyle(color: Colors.white),
              descTextStyle: const TextStyle(color: Colors.white),
              dialogType: DialogType.success,
              animType: AnimType.topSlide,
              title: 'İşlem Başarılı!',
              desc:
                  'Eposta adresi başarıyla değiştirildi!\nDeğişikliklerin uygulanması biraz zaman alabilir.',
              btnOkOnPress: () {},
            ).show();
            localDatabase localDb = localDatabase();
            await localDb.updateOtherMethod(docId, fields) as Future<bool>;
          } else {
            AwesomeDialog(
              context: context,
              dismissOnTouchOutside: false,
              dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
              btnOkColor: const Color.fromARGB(154, 73, 47, 85),
              titleTextStyle: const TextStyle(color: Colors.white),
              descTextStyle: const TextStyle(color: Colors.white),
              dialogType: DialogType.error,
              animType: AnimType.topSlide,
              title: 'İşlem Başarısız.',
              desc: 'Bilinmeyen bir hata çıktı. Daha sonra tekrar dene.',
              btnOkOnPress: () {},
            ).show();
          }
        });
      } else {
        setState(() {
          mailErrorState = true;
          mailErrorText = "Doğrulama kodu hatalı!";
          mailButtonLoading = false;
        });
      }
    }
  }

  void passwordButtonClick() {
    setState(() {
      passButtonLoading = true;
    });
    FocusScope.of(context).unfocus();
    String lastPassword = oldPassTextController.text;
    String newPassword = newPassTextController.text;
    if (lastPassword == newPassword) {
      setState(() {
        passButtonLoading = false;
        passErrorState = true;
        passErrorText = "Yeni şifre, eski şifre ile aynı olamaz.";
      });
    } else if (lastPassword != pass) {
      setState(() {
        passButtonLoading = false;
        pass2ErrorState = true;
        pass2ErrorText = "Eski şifre doğru değil.";
      });
    } else {
      Map<String, dynamic> fields = {
        "password": newPassword,
      };
      database db = database();
      Future<bool> state = db.updateDatas(fields, docId);
      state.then((value) async {
        if (value) {
          setState(() {
            newPassTextController.text = "";
            oldPassTextController.text = "";
            passButtonLoading = false;
            pass = newPassword;
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
            title: 'İşlem Başarılı!',
            desc: 'Şifre başarıyla değiştirildi!',
            btnOkOnPress: () {},
          ).show();
          localDatabase localDb = localDatabase();
          await localDb.updateOtherMethod(docId, fields) as Future<bool>;
        } else {
          setState(() {
            passButtonLoading = false;
          });
          AwesomeDialog(
            context: context,
            dismissOnTouchOutside: false,
            dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
            btnOkColor: const Color.fromARGB(154, 73, 47, 85),
            titleTextStyle: const TextStyle(color: Colors.white),
            descTextStyle: const TextStyle(color: Colors.white),
            dialogType: DialogType.error,
            animType: AnimType.topSlide,
            title: 'İşlem Başarısız.',
            desc: 'Bilinmeyen bir hata çıktı. Daha sonra tekrar dene.',
            btnOkOnPress: () {},
          ).show();
        }
      });
    }
  }

  void phoneButtonClick() {
    setState(() {
      phoneButtonLoading = true;
    });
    if (phoneEP == "1") {
      AwesomeDialog(
              context: context,
              dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
              btnOkColor: Colors.blue,
              titleTextStyle: const TextStyle(color: Colors.white),
              descTextStyle: const TextStyle(color: Colors.white),
              dialogType: DialogType.info,
              btnCancelText: "Bağış Yap",
              btnCancelColor: Colors.green,
              animType: AnimType.bottomSlide,
              title: 'Bilgilendirme',
              desc:
                  'SMS Servis hizmetine sahip olunamadığı için doğrulama yapılamayacaktır. Doğrulama imkanımız olması için bizlere bağış yapabilirsin.',
              btnOkOnPress: () {
                setState(() {
                  phoneEP = "2";
                });
              },
              btnCancelOnPress: () {
                Navigator.popAndPushNamed(context, "/about");
              },
              btnOkText: "Devam.")
          .show();
      setState(() {
        phoneButtonLoading = false;
      });
    } else {
      String phNumber = phoneTextController.text;
      if (phNumber.length != 10) {
        setState(() {
          phoneButtonLoading = false;
          phoneErrorState = true;
          phoneErrorText =
              "Lütfen 10 haneli numaranızı girin. Örn: 555 555 55 55";
        });
        return;
      }
      Map<String, dynamic> fields = {
        "phone": phNumber,
      };
      database db = database();
      Future<bool> state = db.updateDatas(fields, docId);
      state.then((value) async {
        if (value) {
          setState(() {
            phone = phNumber;
            phoneButtonLoading = false;
            phoneTextController.text = "";
            phoneEP = "1";
          });
          AwesomeDialog(
            context: context,
            dismissOnTouchOutside: false,
            dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
            btnOkColor: const Color.fromARGB(154, 73, 47, 85),
            titleTextStyle: const TextStyle(color: Colors.white),
            descTextStyle: const TextStyle(color: Colors.white),
            dialogType: DialogType.success,
            animType: AnimType.topSlide,
            title: 'İşlem Başarılı!',
            desc: 'Telefon Numarası başarıyla değiştirildi!',
            btnOkOnPress: () {},
          ).show();
          localDatabase localDb = localDatabase();
          await localDb.updateOtherMethod(docId, fields) as Future<bool>;
        } else {
          AwesomeDialog(
            context: context,
            dismissOnTouchOutside: false,
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
  }

  void deleteButtonClick() async {
    setState(() {
      deleteButtonLoading = true;
    });
    if (accdelEP == "1") {
      await emailPass().verifyEmail(mail);
      setState(() {
        accdelEP = "2";
        deleteButtonLoading = false;
      });
    } else {
      String code = deleteTextController.text;
      bool control = emailPass().tryVerifyCode(int.parse(code));
      if (control) {
        // ignore: use_build_context_synchronously
        AwesomeDialog(
          context: context,
          dialogBackgroundColor: const Color.fromARGB(255, 73, 47, 85),
          btnOkColor: Colors.red,
          titleTextStyle: const TextStyle(color: Colors.white),
          descTextStyle: const TextStyle(color: Colors.white),
          dialogType: DialogType.warning,
          animType: AnimType.topSlide,
          btnOkText: "Eminim, Silin.",
          title: 'Hey, lütfen iyi düşün.',
          desc:
              'Hesabını kalıcı olarak sileceksin. Verilerin, konuşma geçmişin silinecek.',
          btnOkOnPress: () async {
            database db = database();
            bool state = await db.deleteUser(docId);
            if (state) {
              localDatabase localDb = localDatabase();
              await localDb.deleteUser(docId);
              await Shareds.sharedEkleGuncelle("docId", "");
              await Shareds.sharedEkleGuncelle("loginState", "");
              SystemNavigator.pop();
            }
          },
        ).show();
      } else {
        setState(() {
          deleteButtonLoading = false;
          deleteErrorState = true;
          deleteErrorText = "Kod yanlış. Lütfen tekrar dene.";
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 10), () async {
      header = ModalRoute.of(context)?.settings.arguments as String;
      docId = await Shareds.sharedCek("docId");
      localDatabase db = localDatabase();
      dynamic datas = await db.getUserDatas(docId, "email, password, phone");
      if (datas != null) {
        mail = datas["email"];
        pass = datas["password"];
        phone = datas["phone"];
        setState(() {
          loadScreenState = false;
        });
      } else {
        setState(() {
          loadScreenText = "Hata! Daha sonra tekrar dene.";
        });
      }
    });
  }

  bool mailController(String text) {
    final validPattern = RegExp(r'^[a-zA-Z0-9_.-@]+$');
    return !validPattern.hasMatch(text);
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

  String maskString(String input, int visibleCharacters) {
    if (input.length <= visibleCharacters) {
      return input;
    }
    String maskedPart = "*" * input.length;
    return maskedPart;
  }

  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 10) {
      return "Yok";
    }

    String countryCode = "+90";
    String lastPart = phoneNumber.substring(6, 8);
    String finalPart = phoneNumber.substring(8);

    return "$countryCode *** *** $lastPart $finalPart";
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
            Text(
              "| $header",
              style: const TextStyle(
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
        child: loadScreenState
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      loadScreenText,
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
                padding: const EdgeInsets.only(top: 16, left: 5, right: 5),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(154, 104, 82, 114),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 140, 0, 255)
                              .withOpacity(0.2),
                          blurRadius: 7,
                          offset: const Offset(10, 10),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: const Text("Epostanı Değiştir",
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                      subtitle: Text(maskEmail(mail),
                          style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                enabled: (mailEP == "1") ? false : true,
                                controller: mailTextController,
                                inputFormatters:
                                    (mailEP == "2" || mailEP == "4")
                                        ? <TextInputFormatter>[
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[0-9]')),
                                          ]
                                        : null,
                                keyboardType: (mailEP == "2" || mailEP == "4")
                                    ? TextInputType.number
                                    : TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                maxLength:
                                    (mailEP == "2" || mailEP == "4") ? 7 : 30,
                                decoration: InputDecoration(
                                    border: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 255, 0, 0))),
                                    prefixIcon: const Icon(
                                      Icons.mail,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                    labelText: (mailEP == "1")
                                        ? "Mevcut Epostanı Doğrulamalısın."
                                        : (mailEP == "3")
                                            ? "Yeni Eposta Adresi.."
                                            : "Doğrulama Kodu..",
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    enabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 32, 32, 32))),
                                    focusedBorder: const OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.purple)),
                                    errorText:
                                        mailErrorState ? mailErrorText : null,
                                    counterText: ""),
                                cursorColor: Colors.white,
                                onChanged: (text) {
                                  List<String> words = text.split(' ');
                                  String email = words
                                      .where((word) => word.isNotEmpty)
                                      .join(' ');
                                  text = email;
                                  mailTextController.text = text.toLowerCase();
                                  if (mailController(text) &&
                                      text.isNotEmpty &&
                                      mailEP == "3") {
                                    mailErrorText =
                                        "Lütfen geçerli bir eposta gir.";
                                    setState(() {
                                      mailErrorState = true;
                                    });
                                    return;
                                  }
                                  if (mailErrorState) {
                                    setState(() {
                                      mailErrorState = false;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton(
                                  onPressed: mailButtonLoading
                                      ? null
                                      : mailErrorState
                                          ? null
                                          : emailButtonClick,
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 32, 32, 32),
                                    ),
                                    overlayColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.transparent,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                  child: mailButtonLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color.fromARGB(
                                                        255, 255, 255, 255)),
                                          ))
                                      : mailEP == "1"
                                          ? const Text(
                                              "Doğrulama Kodu Gönder",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              "Devam",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(154, 104, 82, 114),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 140, 0, 255)
                              .withOpacity(0.2),
                          blurRadius: 7,
                          offset: const Offset(10, 10),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: const Text("Şifreni Değiştir",
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                      subtitle: Text(maskString(pass, pass.length > 10 ? 2 : 1),
                          style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: oldPassTextController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 255, 0, 0))),
                                  prefixIcon: const Icon(
                                    Icons.password,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                  labelText: "Eski Şifre",
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 32, 32, 32))),
                                  focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.purple)),
                                  errorText:
                                      pass2ErrorState ? pass2ErrorText : null,
                                ),
                                onChanged: (value) {
                                  if (value.length < 5 || value.length > 30) {
                                    setState(() {
                                      pass2ErrorState = true;
                                      pass2ErrorText =
                                          "Şifre minimum 5, maksimum 30 karakter olabilir.";
                                    });
                                  } else if (pass2ErrorState) {
                                    setState(() {
                                      pass2ErrorState = false;
                                    });
                                  }
                                },
                                obscureText: true,
                                cursorColor: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: newPassTextController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 255, 0, 0))),
                                  prefixIcon: const Icon(
                                    Icons.password,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                  labelText: "Yeni Şifre",
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 32, 32, 32))),
                                  focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.purple)),
                                  errorText:
                                      passErrorState ? passErrorText : null,
                                ),
                                onChanged: (value) {
                                  if (value.length < 5 || value.length > 30) {
                                    setState(() {
                                      passErrorState = true;
                                      passErrorText =
                                          "Şifre minimum 5, maksimum 30 karakter olabilir.";
                                    });
                                  } else if (passErrorState) {
                                    setState(() {
                                      passErrorState = false;
                                    });
                                  }
                                },
                                obscureText: true,
                                cursorColor: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton(
                                  onPressed: passErrorState
                                      ? null
                                      : passwordButtonClick,
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 32, 32, 32),
                                    ),
                                    overlayColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.transparent,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                  child: passButtonLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color.fromARGB(
                                                        255, 255, 255, 255)),
                                          ))
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
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(154, 104, 82, 114),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 140, 0, 255)
                              .withOpacity(0.2),
                          blurRadius: 7,
                          offset: const Offset(10, 10),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: const Text("Telefonunu Değiştir",
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                      subtitle: Text(formatPhoneNumber(phone),
                          style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: phoneTextController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9]')),
                                ],
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 255, 0, 0))),
                                  prefixIcon: const Icon(
                                    Icons.phone_android_rounded,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                  enabled: phoneEP == "1" ? false : true,
                                  labelText: phoneEP == "1"
                                      ? "İlk bilgilendirme metnini okumalısın.."
                                      : "Telefon Numaran",
                                  prefixText: "+90 ",
                                  prefixStyle:
                                      const TextStyle(color: Colors.grey),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 32, 32, 32))),
                                  focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.purple)),
                                  counterText: "",
                                  errorText:
                                      phoneErrorState ? phoneErrorText : null,
                                ),
                                onChanged: (value) {
                                  if (phoneErrorState) {
                                    setState(() {
                                      phoneErrorState = false;
                                    });
                                  }
                                },
                                maxLength: 10,
                                cursorColor: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton(
                                  onPressed: phoneButtonClick,
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 32, 32, 32),
                                    ),
                                    overlayColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.transparent,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    phoneEP == "1"
                                        ? "Bilgilendirme Metnini Göster"
                                        : "Devam",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(154, 104, 82, 114),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 140, 0, 255)
                              .withOpacity(0.2),
                          blurRadius: 7,
                          offset: const Offset(10, 10),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: const Text("Hesabını Sil",
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                      subtitle: const Text(
                          "Geçici hisler için kalıcı kararlar verme.",
                          style: TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: deleteTextController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                enabled: accdelEP == "1" ? false : true,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9]')),
                                ],
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 255, 0, 0))),
                                  prefixIcon: const Icon(
                                    Icons.email,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                  labelText: accdelEP == "1"
                                      ? "Epostana Onay kodu göndereceğiz."
                                      : "Onay Kodunu giriniz.",
                                  prefixStyle:
                                      const TextStyle(color: Colors.grey),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 32, 32, 32))),
                                  focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.purple)),
                                  counterText: "",
                                  errorText:
                                      deleteErrorState ? deleteErrorText : null,
                                ),
                                onChanged: (value) {
                                  if (deleteErrorState) {
                                    setState(() {
                                      deleteErrorState = false;
                                    });
                                  }
                                },
                                maxLength: 10,
                                cursorColor: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: ElevatedButton(
                                  onPressed: deleteButtonLoading
                                      ? null
                                      : deleteErrorState
                                          ? null
                                          : deleteButtonClick,
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 32, 32, 32),
                                    ),
                                    overlayColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.transparent,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                  child: deleteButtonLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color.fromARGB(
                                                        255, 255, 255, 255)),
                                          ))
                                      : Text(
                                          accdelEP == "1"
                                              ? "Kararlıyım, gönderin."
                                              : "Hesabımı Sil",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
