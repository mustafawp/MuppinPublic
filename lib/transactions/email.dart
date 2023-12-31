import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

var codes = 0;

// ignore: camel_case_types
class emailPass {
  String mymail = "muppinapp@gmail.com";
  String password = "hurexjwgbpcpfsbs";

  Future<bool> registerCodePass(String email) async {
    try {
      codes = Random().nextInt(999999) + 100000;
      final smtpServer = gmail(mymail, password);
      final message = Message()
        ..from = Address(mymail, "Muppin")
        ..recipients.add(email)
        ..subject = 'Doğrulama Kodu: $codes'
        ..html = '''
        <html>
          <body>
            <div style="background-color: #492f55; padding: 20px; font-family: Arial, sans-serif; color: #fff;">
              <div style="background-color: #c35aff; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
                <h1 style="color: #ffffff">Merhaba! Seni görmek güzel!</h1>
                <p style="color: #ffffff">Aramıza katılmak için son bir aşama kaldı!</p>
                <p style="color: #ffffff">Epostanı onaylaman için gereken kod:</p>
                <h2 style="color: #ffffff;">$codes</h2>
                <p style="color: #ffffff;">İyi Günler!</p>
                <p style="font-size: 12px; color: #333333;">Muppin Corporation | Copyright 2023</p>
              </div>
            </div>
          </body>
        </html>
      ''';

      try {
        // ignore: unused_local_variable
        final sendReport = await send(message, smtpServer);
      } catch (e) {
        if (kDebugMode) {
          print('E-posta gönderilirken hata oluştu: $e');
        }
      }
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> saveCodePass(String email, String username) async {
    try {
      codes = Random().nextInt(999999) + 100000;
      final smtpServer = gmail(mymail, password);
      final message = Message()
        ..from = Address(mymail, "Muppin")
        ..recipients.add(email)
        ..subject = 'Doğrulama Kodu: $codes'
        ..html = '''
        <html>
          <body>
            <div style="background-color: #492f55; padding: 20px; font-family: Arial, sans-serif; color: #fff;">
              <div style="background-color: #c35aff; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
                <h1 style="color: #ffffff">Yetiştimm! $username</h1>
                <p style="color: #ffffff">Merhaba, $username Görüyoruz ki şifreni unutmuşsun!</p>
                <p style="color: #ffffff">İşte! Aşağıdaki kodu uygulamamıza yazarak şifreni sıfırlayabilirsin!</p>
                <h2 style="color: #ffffff;">$codes</h2>
                <p style="color: #ffffff;">İyi Günler!</p>
                <p style="font-size: 12px; color: #333333;">Muppin Corporation | Copyright 2023</p>
              </div>
            </div>
          </body>
        </html>
      ''';

      try {
        // ignore: unused_local_variable
        final sendReport = await send(message, smtpServer);
      } catch (e) {
        if (kDebugMode) {
          print('E-posta gönderilirken hata oluştu: $e');
        }
      }
      return true;
    } catch (err) {
      return false;
    }
  }

  bool tryVerifyCode(int code) {
    return (codes == code);
  }

  Future<bool> verifyEmail(String email) async {
    try {
      codes = Random().nextInt(999999) + 100000;
      final smtpServer = gmail(mymail, password);
      final message = Message()
        ..from = Address(mymail, "Muppin")
        ..recipients.add(email)
        ..subject = 'Doğrulama Kodu: $codes'
        ..html = '''
        <html>
          <body>
            <div style="background-color: #492f55; padding: 20px; font-family: Arial, sans-serif; color: #fff;">
              <div style="background-color: #c35aff; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
                <h1 style="color: #ffffff">Tekrardan selam!</h1>
                <p style="color: #ffffff">Epostanı onaylamak için aşağıdaki kodu uygulamaya girmeye ne dersin?</p>
                <p style="color: #ffffff">Epostanı onaylaman için gereken kod:</p>
                <h2 style="color: #ffffff;">$codes</h2>
                <p style="color: #ffffff;">İyi Günler!</p>
                <p style="font-size: 12px; color: #333333;">Muppin Corporation | Copyright 2023</p>
              </div>
            </div>
          </body>
        </html>
      ''';

      try {
        // ignore: unused_local_variable
        final sendReport = await send(message, smtpServer);
      } catch (e) {
        if (kDebugMode) {
          print('E-posta gönderilirken hata oluştu: $e');
        }
      }
      return true;
    } catch (err) {
      return false;
    }
  }
}
