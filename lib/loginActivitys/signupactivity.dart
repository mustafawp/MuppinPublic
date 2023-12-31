// ignore_for_file: use_build_context_synchronously
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/email.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:muppin_app/transactions/shareds.dart';

// ignore: camel_case_types, use_key_in_widget_constructors
class signupactivity extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _signupActivityState createState() => _signupActivityState();
}

// ignore: camel_case_types
class _signupActivityState extends State<signupactivity> {
  bool isUsernameFieldVisible = true;
  bool isPasswordFieldVisible = false;
  bool isEmailFieldVisible = false;
  bool isLoading = false;
  bool isVerificationCodeFieldVisible = false;
  bool isPasswordVisible = false;
  bool isErrorState = false; // Hata durumu
  String isErrorText = ""; // Hata mesajı
  String uname = "", psw = "", eml = "";
  bool internetVarMi = false;
  // ignore: prefer_final_fields
  Color _counterTextColor = Colors.white;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController verificationCodeController = TextEditingController();

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

  void changeFields() async {
    setState(() {
      FocusScope.of(context).unfocus();
      if (isUsernameFieldVisible) {
        usernameControls();
      } else if (isPasswordFieldVisible) {
        passwordControls();
      } else if (isEmailFieldVisible) {
        emailControls();
      } else if (isVerificationCodeFieldVisible) {
        codeControls();
      }
    });
  }

  bool containsInvalidCharacters(String text) {
    final validPattern = RegExp(r'^[a-z-0-9_\s]+$');
    if (!validPattern.hasMatch(text)) {
      return true;
    }
    return false;
  }

  bool containsLetter(String text) {
    for (int i = 0; i < text.length; i++) {
      if (text[i].toUpperCase() != text[i].toLowerCase()) {
        return true;
      }
    }
    return false;
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

  void usernameControls() async {
    if (isErrorState) return;
    if (isLoading) return;
    isLoading = true;
    String username = usernameController.text;
    if (!containsLetter(username)) {
      usernameController.text = "";
      isErrorText = "Kullanıcı adı en az 1 harf içermeli.";
      isErrorState = true;
      isLoading = false;
      return;
    }

    if (!isValidUsername(username)) {
      usernameController.text = "";
      isErrorText = "Kullanıcı adı . veya _ ile başlayamaz, yan yana olamaz.";
      isErrorState = true;
      isLoading = false;
      return;
    }
    List<String> words = username.split(' ');
    username = words.where((word) => word.isNotEmpty).join(' ');
    if (containsInvalidCharacters(username)) {
      usernameController.text = "";
      isErrorText = "Geçersiz Karakterler. (Yalnızca a-z, 0-9 ve _)";
      isErrorState = true;
      isLoading = false;
      return;
    } else if (username.length < 4 || username.length > 20) {
      usernameController.text = "";
      isErrorText = "Kullanıcı adı en az 4, en fazla 20 karakter olabilir.";
      isErrorState = true;
      isLoading = false;
      return;
    }
    await _checkInternetConnection();
    if (internetVarMi) {
      Fluttertoast.showToast(
          msg: "İnternet Bağlantın olmadan bu işlemi yapamazsın.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      isLoading = false;
      return;
    }
    database db = database();
    Future<bool> state = db.getUsersByField("username", username);
    state.then((value) {
      if (value) {
        setState(() {
          isLoading = false;
          usernameController.text = "";
          isErrorState = true;
          isErrorText =
              "Bu kullanıcı adı zaten başka biri tarafından kullanılıyor.";
        });
        isLoading = false;
        return;
      } else {
        setState(() {
          isLoading = false;
          uname = username;
          isUsernameFieldVisible = false;
          isPasswordFieldVisible = true;
        });
      }
    });
  }

  void passwordControls() {
    if (isErrorState) return;
    if (passwordController.text.length < 5 ||
        passwordController.text.length > 30) {
      passwordController.text = "";
      isErrorText = "Daha güçlü bir şifre seç. (Min 5 Max 30 karakter)";
      isErrorState = true;
    } else {
      psw = passwordController.text;
      isPasswordFieldVisible = false;
      isEmailFieldVisible = true;
    }
  }

  void emailControls() async {
    if (isErrorState) return;
    isLoading = true;
    String email = emailController.text;
    if (email.length < 8 || email.length > 40) {
      usernameController.text = "";
      isErrorText = "Lütfen geçerli bir Eposta Adresi girin.";
      isErrorState = true;
      isLoading = false;
    } else if (!email.contains("@") && !email.contains(".com")) {
      usernameController.text = "";
      isErrorText = "Lütfen geçerli bir Eposta Adresi girin.";
      isErrorState = true;
      isLoading = false;
    } else if (email.contains("@gmail.com") && email != "@gmail.com" ||
        email.contains("@hotmail.com") && email != "@hotmail.com" ||
        email.contains("@outlook.com") && email != "@outlook.com" ||
        email.contains("@yahoo.com") && email != "@yahoo.com" ||
        email.contains("@yandex.com") && email != "@yandex.com") {
      await _checkInternetConnection();
      if (internetVarMi) {
        Fluttertoast.showToast(
            msg: "İnternet Bağlantın olmadan bu işlemi yapamazsın.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        isLoading = false;
        return;
      }
      database db = database();
      Future<bool> state = db.getUsersByField("email", email);
      state.then((value) {
        if (value && !isErrorState) {
          usernameController.text = "";
          isErrorText = "Bu Eposta zaten başka biri tarafından kullanılıyor.";
          setState(() {
            isErrorState = true;
            isLoading = false;
          });
          return;
        } else {
          emailPass().registerCodePass(email);
          setState(() {
            eml = email;
            isEmailFieldVisible = false;
            isVerificationCodeFieldVisible = true;
            isLoading = false;
          });
        }
      });
    } else {
      emailController.text = "";
      isErrorText = "Lütfen geçerli bir Eposta Adresi girin.";
      isErrorState = true;
      isLoading = false;
    }
  }

  void codeControls() async {
    if (isErrorState) return;
    isLoading = true;
    String verificationCode = verificationCodeController.text;
    if (verificationCode.length < 6 || verificationCode.length > 7) {
      verificationCodeController.text = "";
      isErrorText = "Lütfen geçerli bir doğrulama kodu girin.";
      isErrorState = true;
      isLoading = false;
      return;
    }
    // ignore: await_only_futures
    bool state = await emailPass().tryVerifyCode(int.parse(verificationCode));
    if (state) {
      await _checkInternetConnection();
      if (internetVarMi) {
        Fluttertoast.showToast(
            msg: "İnternet Bağlantın olmadan bu işlemi yapamazsın.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        isLoading = false;
        return;
      }
      AwesomeDialog(
        context: context,
        dismissOnTouchOutside: false,
        dialogBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
        btnOkColor: Colors.green,
        btnCancelColor: Colors.red,
        titleTextStyle: const TextStyle(color: Colors.white),
        descTextStyle: const TextStyle(color: Colors.white),
        dialogType: DialogType.question,
        animType: AnimType.topSlide,
        btnOkText: "Kabul Ediyorum.",
        btnCancelText: "Sözleşmeyi Gör",
        title: 'Kullanım Koşullarını kabul ediyor musun?',
        desc:
            'Kullanım Koşullarını ve Gizlilik Politikasını görmek için "Sözleşmeyi Gör" butonuna tıklayınız. Kabul etmek için ise "Kabul Ediyorum" butonuna tıklayın.',
        btnOkOnPress: () {
          final now = DateTime.now();

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

          String formattedDate = DateFormat('dd MMMM y').format(now);
          months.forEach((ingilizce, turkce) {
            formattedDate = formattedDate.replaceAll(ingilizce, turkce);
          });
          Map<String, dynamic> socials = {};
          List emptyList = [];
          Map<String, dynamic> fields = {
            "username": uname,
            "password": psw,
            "email": eml,
            "about": "Merhaba! Ben Muppin Kullanıyorum!",
            "security": "false",
            "pp": "-",
            "badges": emptyList,
            "socials": socials,
            "joined": formattedDate,
            "birthday": "",
            "gender": "",
            "pronouns": "",
            "phone": "",
          };
          database db = database();
          Future<bool> control = db.addUser(fields);
          control.then((success) async {
            if (success) {
              await Shareds.sharedEkleGuncelle("loginState", "true");
              await Shareds.sharedEkleGuncelle(
                  "account", usernameController.text);
              Navigator.pop(context);
              Navigator.of(context).pop();
              Navigator.pushNamed(context, "/home");
            } else {
              verificationCodeController.text = "";
              isErrorText = "Bir hata oluştu, lütfen tekrar dene.";
              isErrorState = true;
              isLoading = false;
            }
          });
        },
        btnCancelOnPress: () {
          setState(() {
            isLoading = false;
          });
          Navigator.pushNamed(context, "/politics");
        },
      ).show();
    } else {
      verificationCodeController.text = "";
      isErrorText = "Doğrulama kodu yanlış. Lütfen tekrar dene.";
      isErrorState = true;
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isUsernameFieldVisible
                    ? 'Sana özel havalı bir kullanıcı adı ayarla.'
                    : isPasswordFieldVisible
                        ? 'Şifreni zor bir şey yap, unutursan sana yardım ederiz :)'
                        : isEmailFieldVisible
                            ? 'Sanırım burası hesabın için en önemli kısım.'
                            : 'Hey! E-Postanı kontrol et!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (isUsernameFieldVisible)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextField(
                        maxLength: 20,
                        controller: usernameController,
                        onChanged: (text) {
                          List<String> words = text.split(' ');
                          String username =
                              words.where((word) => word.isNotEmpty).join(' ');
                          text = username;
                          usernameController.text = text.toLowerCase();
                          usernameController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: usernameController.text.length),
                          );
                          if (containsInvalidCharacters(text)) {
                            isErrorText =
                                "Yalnızca a-z, 0-9 ve _ Kullanılabilir.";
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
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isUsernameFieldVisible
                              ? Colors.white
                              : Colors.grey[300],
                          hintText: 'Kullanıcı Adı',
                          hintStyle: const TextStyle(
                              color: Color.fromARGB(255, 138, 138, 138)),
                          prefixIcon: const Icon(Icons.person,
                              color: Color.fromARGB(255, 32, 32, 32)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(
                                color: Color.fromARGB(255, 32, 32, 32)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(
                                color: Color.fromARGB(255, 32, 32, 32)),
                          ),
                          counterStyle: TextStyle(color: _counterTextColor),
                          errorText: isErrorState ? isErrorText : null,
                        ),
                      ),
                    ),
                  ],
                ),
              if (isPasswordFieldVisible)
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: passwordController,
                    onChanged: (value) {
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
                          : Colors.grey[300],
                      hintText: 'Şifre',
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 139, 139, 139)),
                      prefixIcon: const Icon(Icons.lock,
                          color: Color.fromARGB(255, 32, 32, 32)),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                        child: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color.fromARGB(255, 32, 32, 32),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 32, 32, 32)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 32, 32, 32)),
                      ),
                      errorText: isErrorState ? isErrorText : null,
                    ),
                    obscureText: !isPasswordVisible,
                  ),
                ),
              if (isEmailFieldVisible)
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (text) {
                      List<String> words = text.split(' ');
                      String email =
                          words.where((word) => word.isNotEmpty).join(' ');
                      text = email;
                      emailController.text = text.toLowerCase();
                      emailController.selection = TextSelection.fromPosition(
                        TextPosition(offset: emailController.text.length),
                      );
                      if (isErrorState) {
                        setState(() {
                          isErrorState = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          isEmailFieldVisible ? Colors.white : Colors.grey[300],
                      hintText: 'E-posta Adresi',
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 108, 108, 108)),
                      prefixIcon: const Icon(Icons.email,
                          color: Color.fromARGB(255, 32, 32, 32)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 32, 32, 32)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 32, 32, 32)),
                      ),
                      errorText: isErrorState ? isErrorText : null,
                    ),
                  ),
                ),
              if (isVerificationCodeFieldVisible)
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    onChanged: (value) {
                      if (isErrorState) {
                        setState(() {
                          isErrorState = false;
                        });
                      }
                    },
                    controller: verificationCodeController,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isVerificationCodeFieldVisible
                          ? Colors.white
                          : Colors.grey[300],
                      hintText: 'E-posta Onay Kodu',
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 114, 114, 114)),
                      prefixIcon: const Icon(Icons.confirmation_number,
                          color: Color.fromARGB(255, 32, 32, 32)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 32, 32, 32)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 32, 32, 32)),
                      ),
                      errorText: isErrorState ? isErrorText : null,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color.fromARGB(2255, 255, 255, 255),
                    backgroundColor: const Color.fromARGB(154, 73, 47, 85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: isLoading ? null : changeFields,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 255, 255, 255)),
                          ),
                        )
                      : Text(
                          isUsernameFieldVisible
                              ? 'Devam Et'
                              : isPasswordFieldVisible
                                  ? 'Devam Et'
                                  : isEmailFieldVisible
                                      ? 'Devam Et'
                                      : 'Kayıt Ol',
                          style: const TextStyle(color: Colors.white),
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
