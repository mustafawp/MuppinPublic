import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:muppin_app/database/users.dart';
import 'package:muppin_app/transactions/email.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:muppin_app/transactions/userdata.dart';

// ignore: camel_case_types, use_key_in_widget_constructors
class saveaccount extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _saveAccountState createState() => _saveAccountState();
}

// ignore: camel_case_types
class _saveAccountState extends State<saveaccount> {
  bool isPasswordFieldVisible = false;
  bool isEmailFieldVisible = true;
  bool isLoading = false;
  bool isVerificationCodeFieldVisible = false;
  bool isPasswordVisible = false;
  bool isErrorState = false;
  String isErrorText = "Bilinmeyen Hata Oluştu. Lütfen tekrar dene.";
  String uname = "", psw = "", eml = "";
  bool internetVarMi = false;
  String documentId = "";
  String username = "";

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
      if (isEmailFieldVisible) {
        emailControls();
      } else if (isVerificationCodeFieldVisible) {
        codeControls();
      } else if (isPasswordFieldVisible) {
        passwordControls();
      }
    });
  }

  bool containsInvalidCharacters(String text) {
    final validPattern = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!validPattern.hasMatch(text)) {
      return true;
    }
    return false;
  }

  void passwordControls() async {
    if (isErrorState) return;
    isLoading = true;
    String password = passwordController.text;
    if (password.length < 5 || password.length > 30) {
      passwordController.text = "";
      isErrorText = "Daha güçlü bir şifre seç. (Min 5 Max 30 karakter)";
      isErrorState = true;
      isLoading = false;
    } else {
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
      Map<String, dynamic> fields = {
        "password": password,
      };
      database db = database();
      Future<bool> state = db.updateDatas(fields, documentId);
      state.then((value) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: value
              ? "Başarıyla Şifre Sıfırlandı!"
              : "Bir hata oluştu, daha sonra tekrar dene.",
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      });
    }
  }

  void emailControls() async {
    if (isErrorState) return;
    isLoading = true;
    String email = emailController.text;
    if (email.length < 8 || email.length > 30) {
      emailController.text = "";
      isErrorText = "Lütfen geçerli bir Eposta Adresi girin.";
      isErrorState = true;
      isLoading = false;
    } else if (!email.contains("@") && !email.contains(".com")) {
      emailController.text = "";
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
      List<String> datas = ["documentId", "username"];
      database db = database();
      Future<UserData> state =
          db.getUserDatasFromFieldName(datas, email, "email");
      state.then((value) {
        List<dynamic> redatas = value.data;
        print("data1: ${redatas[0]} data2: ${redatas[1].toString()}");
        if (value.success == true && !isErrorState) {
          documentId = redatas[0];
          username = redatas[1];
          emailPass().saveCodePass(email, username);
          setState(() {
            eml = email;
            isEmailFieldVisible = false;
            isVerificationCodeFieldVisible = true;
            isLoading = false;
          });
        } else {
          emailController.text = "";
          isErrorText = "Bu Epostaya sahip bir hesap bulunamadı.";
          setState(() {
            isErrorState = true;
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
    // ignore: await_only_futures
    bool state = await emailPass().tryVerifyCode(int.parse(verificationCode));
    if (state) {
      isVerificationCodeFieldVisible = false;
      isPasswordFieldVisible = true;
      isLoading = false;
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
                isPasswordFieldVisible
                    ? 'Yeni şifre belirleme zamanı!'
                    : isEmailFieldVisible
                        ? 'Hesabının E-Posta Adresini yaz..'
                        : 'E-Postana gönderdiğimiz kodu gir!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (isPasswordFieldVisible)
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
                    controller: passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isPasswordFieldVisible
                          ? Colors.white
                          : Colors.grey[300],
                      hintText: 'Yeni Şifre..',
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 136, 136, 136)),
                      prefixIcon: const Icon(Icons.lock,
                          color: Color.fromARGB(255, 64, 64, 64)),
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
                          color: const Color.fromARGB(255, 64, 64, 64),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 64, 64, 64)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 64, 64, 64)),
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
                      String username =
                          words.where((word) => word.isNotEmpty).join(' ');
                      text = username;
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
                      hintText: 'Kayıtlı E-Posta Adresi..',
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 130, 130, 130)),
                      prefixIcon: const Icon(Icons.email,
                          color: Color.fromARGB(255, 64, 64, 64)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 64, 64, 64)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 64, 64, 64)),
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
                      hintText: 'Doğrulama Kodu..',
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 121, 121, 121)),
                      prefixIcon: const Icon(Icons.confirmation_number,
                          color: Color.fromARGB(255, 64, 64, 64)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 64, 64, 64)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 64, 64, 64)),
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
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                          isPasswordFieldVisible
                              ? 'Kaydet'
                              : isEmailFieldVisible
                                  ? 'Devam Et'
                                  : 'Devam Et',
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
