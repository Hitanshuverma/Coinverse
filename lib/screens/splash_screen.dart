import 'dart:developer';
import 'package:coinverse/screens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../api/api.dart';
import '../const/constants.dart';
import '../main.dart';
import 'auth/loginScreen.dart';


//splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      //exit full-screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          systemNavigationBarColor: AppColor.appPrimaryColor,
          statusBarColor: AppColor.appPrimaryColor));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      if (APIs.auth.currentUser != null) {
        log('\nUser: ${APIs.auth.currentUser}');
        //navigate to home screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        //navigate to login screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //initializing media query (for getting device screen size)
    mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColor.appPrimaryColor,
      //body
      body: Container(
        // color: Colors.red,
        // height: mq.height,
        child: Center(
          child: Lottie.asset('assets/images/splash.json', height: 2*mq.height, width: mq.height),
        ),
      ),
    );
  }
}
