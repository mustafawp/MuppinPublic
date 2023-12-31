// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:muppin_app/database/users.dart';
import 'package:http/http.dart' as http;
import 'package:muppin_app/transactions/noscrolleffect.dart';
import 'package:muppin_app/transactions/shareds.dart';

// ignore: use_key_in_widget_constructors, camel_case_types
class signinactivity extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _signinActivityState createState() => _signinActivityState();
}

// ignore: camel_case_types
class _signinActivityState extends State<signinactivity> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isErrorState = false;
  bool isKeyboardVisible = false;
  String isErrorText = "";
  String acname = "";
  String pass = "";
  bool isLoading = false;
  bool isPasswordFieldVisible = true;
  bool internetVarMi = false;
  TextEditingController usernameController = TextEditingController();

  void transactions() {
    setState(() {
      logIn();
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      final response = await http.head(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        setState(() {
          internetVarMi = false;
        });
      } else {
        setState(() {
          internetVarMi = true;
        });
      }
    } catch (e) {
      setState(() {
        internetVarMi = true;
      });
    }
  }

  void logIn() async {
    if (isErrorState) return;
    isLoading = true;

    // karakter sayısı kontrolü
    if (acname.length < 3 || acname.length > 40) {
      isErrorText = "Lütfen geçerli bir kullanıcı adı veya eposta girin.";
      isErrorState = true;
      isLoading = false;
      return;
    }

    // şifre karakteri kontrolü
    if (pass.length < 3 || pass.length > 20) {
      isErrorText = "Lütfen geçerli bir şifre girin.";
      isErrorState = true;
      isLoading = false;
      return;
    }

    // özel karakter kontrolü
    List<String> words = acname.split(' ');
    acname = words.where((word) => word.isNotEmpty).join(' ');
    if (containsInvalidCharacters(acname)) {
      isErrorText = "Lütfen geçerli bir kullanıcı adı girin.";
      isErrorState = true;
      isLoading = false;
      return;
    }

    // internet kontrolü
    await _checkInternetConnection();
    if (internetVarMi) {
      isLoading = false;
      Fluttertoast.showToast(
          msg: "İnternet Bağlantın olmadan bu işlemi yapamazsın.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    // veritabanı kontrolleri
    database db = database();
    String loginResult = await db.logInControl(acname, pass);
    if (loginResult == "dogrulandi") {
      await Shareds.sharedEkleGuncelle("loginState", "true");
      await Shareds.sharedEkleGuncelle("account", acname);
      Navigator.pop(context);
      Navigator.pushNamed(context, "/home");
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isErrorText = loginResult.toString();
        isErrorState = true;
        isLoading = false;
      });
    }
  }

  bool containsInvalidCharacters(String text) {
    final validPattern = RegExp(r'^[a-z-0-9_\s\@\.]+$');
    if (!validPattern.hasMatch(text)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      body: ScrollConfiguration(
        behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        const SizedBox(height: 30.0),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0)),
                          ),
                          child: TextField(
                            maxLength: 40,
                            controller: usernameController,
                            onChanged: (value) {
                              List<String> words = value.split(' ');
                              String username = words
                                  .where((word) => word.isNotEmpty)
                                  .join(' ');
                              value = username;
                              usernameController.text = value.toLowerCase();
                              usernameController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: usernameController.text.length),
                              );
                              acname = value;
                              if (containsInvalidCharacters(value)) {
                                isErrorText =
                                    "Yalnızca a-z, 0-9, @ ve . Kullanılabilir.";
                                setState(() {
                                  isErrorState = true;
                                });
                                return;
                              }
                              if (isErrorState) {
                                setState(() {
                                  isErrorState = false;
                                });
                              }
                            },
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: [AutofillHints.email],
                            decoration: const InputDecoration(
                              hintText: 'Eposta veya kullanıcı adı',
                              hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 123, 123, 123)),
                              prefixIcon: Icon(
                                Icons.person,
                                color: Color.fromARGB(255, 32, 32, 32),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 20.0,
                              ),
                              counterText: "",
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        SizedBox(
                          width: double.infinity,
                          child: TextField(
                            onChanged: (value) {
                              pass = value;
                              if (isErrorState) {
                                setState(() {
                                  isErrorState = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isPasswordFieldVisible
                                  ? Colors.white
                                  : const Color.fromARGB(255, 255, 255, 255),
                              hintText: 'Şifre',
                              hintStyle: const TextStyle(
                                  color: Color.fromARGB(255, 123, 123, 123)),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Color.fromARGB(255, 32, 32, 32),
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isPasswordFieldVisible =
                                        !isPasswordFieldVisible;
                                  });
                                },
                                child: Icon(
                                  isPasswordFieldVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color.fromARGB(255, 32, 32, 32),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 64, 64, 64)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 64, 64, 64)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 64, 64, 64)),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 64, 64, 64)),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 64, 64, 64)),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              errorText: isErrorState ? isErrorText : null,
                            ),
                            obscureText: !isPasswordFieldVisible,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(154, 73, 47, 85),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              onPressed: isLoading ? null : transactions,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<
                                                Color>(
                                            Color.fromARGB(255, 159, 159, 159)),
                                      ),
                                    )
                                  : const Text("Giriş Yap"),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Hesap detaylarını mı unuttun?",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, "/saveacc");
                                },
                                child: const Text(
                                  "Giriş için yardım al.",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]),
                        const SizedBox(
                          height: 10,
                        ),
                        const Divider(
                          color: Colors.grey,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Henüz hesap oluşturmadın mı?",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, "/signup");
                                },
                                child: const Text(
                                  "Hesap Oluştur!",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "/politics");
                      },
                      child: const Text(
                        "Kullanım Koşulları & Gizlilik Politikası",
                        style: TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                    ),
                    const Divider(
                      color: Colors.black,
                    ),
                    const Text(
                      "version: BETA 0.0.1",
                      style: TextStyle(color: Colors.grey, fontSize: 8),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
