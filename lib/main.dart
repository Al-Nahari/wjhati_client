import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';       // 1️⃣
import 'package:untitled5/screens/notifications_screen.dart';
import 'package:untitled5/services/notification_provider.dart';
import 'services/AuthService.dart';
import 'services/notification_service.dart';
import 'screens/LoginScreen.dart';
import 'screens/home_screen.dart';
import 'screens/modern_chat_list_screen.dart';
import 'screens/trip_tracking_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/TransfersPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2️⃣ جهّز بيانات التواريخ للعربية
  await initializeDateFormatting('ar', null);

  // 3️⃣ تهيئة إشعارات الجهاز
  NotificationService();

  // 4️⃣ تحقق من حالة تسجيل الدخول
  final bool isLoggedIn = await AuthService.isLoggedIn();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  static const Color primry = Color(0xff2d4960);
  static const Color cardColor = Color(0xff2d4960);
  static const Color accent = Color(0xff2d4960);
  static const Color textLight = Colors.white;
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/Home' : '/Login',
      routes: {
        '/Login': (_) => const LoginScreen(),
        '/Home': (_) => const HomeScreen(),
        '/Complaint': (_) => const ModernChatListScreen(),
        '/TripTracking': (_) => const BookingsPage(),
        '/Wallet': (_) => const WalletPage(),
        '/HomePage': (_) => WalletTransfersPage(walletId: -1),
        '/Notifications': (_) => const NotificationsPage(),
      },
      theme: ThemeData(
        primaryColor: primry,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: primry,
          foregroundColor: textLight,
        ),
      ),
    );
  }
}
