import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:muppin_app/loginActivitys/saveaccount.dart';
import 'package:muppin_app/loginActivitys/signinactivity.dart';
import 'package:muppin_app/loginActivitys/signupactivity.dart';
import 'package:muppin_app/pages/politics_page.dart';
import 'package:muppin_app/screens/aboutscreen.dart';
import 'package:muppin_app/screens/followdetail.dart';
import 'package:muppin_app/screens/homescreen.dart';
import 'package:muppin_app/screens/notificationScreen.dart';
import 'package:muppin_app/screens/othersprofile.dart';
import 'package:muppin_app/screens/profileedit.dart';
import 'package:muppin_app/screens/searchscreen.dart';
import 'package:muppin_app/screens/settingsScreens/accountsettings.dart';
import 'package:muppin_app/screens/settingsscreen.dart';
import 'package:muppin_app/transactions/firebase_options.dart';
import 'package:muppin_app/transactions/shareds.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(muppinApp());
}

// ignore: camel_case_types, use_key_in_widget_constructors
class muppinApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/signin': (context) => signinactivity(),
        '/signup': (context) => signupactivity(),
        '/saveacc': (context) => saveaccount(),
        '/home': (context) => HomeScreen(),
        '/profileEdit': (context) => profileEdit(),
        '/settings': (context) => settingsScreen(),
        '/accountsettings': (context) => accountSettings(),
        '/otherProfile': (context) => othersProfileScreen(),
        '/about': (context) => const aboutScreen(),
        '/followDetail': (context) => const followDetail(),
        '/notifications': (context) => const notificationScreen(),
        '/search': (context) => const searchScreen(),
        '/politics': (context) => const politicsPage(),
      },
    );
  }
}

// ignore: use_key_in_widget_constructors
class SplashScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _splashscreenState createState() => _splashscreenState();
}

// ignore: camel_case_types
class _splashscreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initConfigures();
    });
  }

  void initConfigures() async {
    String data = await Shareds.sharedCek("loginState");
    if (data == "Değer Bulunamadı" || data == "false" || data == "null") {
      // ignore: use_build_context_synchronously
      Navigator.popAndPushNamed(context, "/signin");
    } else {
      // ignore: use_build_context_synchronously
      Navigator.popAndPushNamed(context, "/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
      ),
    );
  }
}
