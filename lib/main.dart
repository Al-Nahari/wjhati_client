import 'package:flutter/material.dart';
import 'package:untitled5/screens/home_screen.dart';

import 'screens/complaint_screen.dart';
import 'screens/trip_tracking_screen.dart';
import 'screens/wallet_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (ctx) => HomeScreen(),
        '/Complaint': (ctx) => ComplaintScreen(),
        '/TripTracking': (ctx) => TripTrackingScreen(),
        '/Wallet': (ctx) => WalletScreen(),
      },
    );
  }
}