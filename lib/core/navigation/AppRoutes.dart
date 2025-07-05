import 'package:flutter/material.dart';
import 'package:journeycraft/views/auth/LoginPage.dart';
import 'package:journeycraft/views/auth/RegisterPage.dart';
import 'package:journeycraft/views/home/HomePage.dart';
import 'package:journeycraft/views/onboarding/WelcomePage.dart';
import 'package:journeycraft/views/kyc/KycPage.dart';
import 'package:journeycraft/views/profile/ProfilePage.dart';
import 'package:journeycraft/views/profile/ProfileCountry.dart';
import 'package:journeycraft/views/profile/ProfileCurrency.dart';
import 'package:journeycraft/views/chat/ChatPage.dart';
import 'package:journeycraft/views/chat/ChatHistoryPage.dart'; // ← THIS LINE IS MISSING

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String kyc = '/kyc';
  static const String profile = '/profile';
  static const String profileCountry = '/profile/country';
  static const String profileCurrency = '/profile/currency';
  static const String chat = '/chat';
  static const String chatHistory = '/chat-history'; // ✅ Added

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
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case profileCountry:
        return MaterialPageRoute(builder: (_) => const ProfileCountryPage());
      case profileCurrency:
        return MaterialPageRoute(builder: (_) => const ProfileCurrencyPage());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatPage());
      case chatHistory:
        return MaterialPageRoute(builder: (_) => const ChatHistoryPage());
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
