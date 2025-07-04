import 'package:flutter/material.dart';
import 'package:journeycraft/views/auth/LoginPage.dart';
import 'package:journeycraft/views/auth/RegisterPage.dart';
import 'package:journeycraft/views/home/HomePage.dart';
import 'package:journeycraft/views/onboarding/WelcomePage.dart';
import 'package:journeycraft/views/home/MapPage.dart';
import 'package:journeycraft/views/kyc/KycPage.dart'; // <-- Make sure your KYCPage is in this folder

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String map = '/map';
  static const String kyc = '/kyc';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case kyc:
        return MaterialPageRoute(builder: (_) => const KYCPage());
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
