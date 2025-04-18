import 'package:flutter/material.dart';
import 'package:untitled5/screens/TransfersPage.dart';
import 'package:untitled5/screens/home_screen.dart';
import 'package:untitled5/services/AuthService.dart';

import 'screens/LoginScreen.dart';
import 'screens/modern_chat_list_screen.dart';
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
  static const Color primry =  Color(0xff2d4960);
  static const Color cardColor = Color(0xff2d4960);
  static const Color accent = Color(0xff2d4960); // أصفر ذهبي
  static const Color textLight = Colors.white;
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
        '/Complaint': (ctx) => ModernChatListScreen(),
        '/TripTracking': (ctx) => BookingsPage(),
        '/Wallet': (ctx) => WalletPage(),
        '/Login': (ctx) => LoginScreen(),
        '/HomePage': (ctx) => WalletTransfersPage(walletId: -1,),
      },
    );
  }
}

