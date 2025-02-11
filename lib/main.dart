import 'package:flutter/material.dart';
import 'package:untitled5/screens/home_screen.dart';
import 'package:untitled5/services/AuthService.dart';

import 'screens/LoginScreen.dart';
import 'screens/complaint_screen.dart';
import 'screens/trip_tracking_screen.dart';
import 'screens/wallet_screen.dart';

void main() async {
  // تأكد من تهيئة Widgets قبل استخدام عمليات غير متزامنة
  WidgetsFlutterBinding.ensureInitialized();
  // التحقق مما إذا كان المستخدم مسجلاً (بوجود بيانات المستخدم في SharedPreferences)
  bool isLoggedIn = await AuthService.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      // إذا كان المستخدم مسجلاً، نعرض الواجهة الرئيسية، وإلا نعرض شاشة تسجيل الدخول
      routes: {
        '/': (ctx) =>isLoggedIn ? const HomeScreen() : const LoginScreen(),
        '/Home': (ctx) => HomeScreen(),
        '/Complaint': (ctx) => ChatListScreen(),
        '/TripTracking': (ctx) => BookingsPage(),
        '/Wallet': (ctx) => WalletPage(),
        '/Login': (ctx) => LoginScreen(),
      },
    );
  }
}
