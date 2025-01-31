import 'package:flutter/material.dart';
import '../screens/complaint_screen.dart';
import '../screens/trip_tracking_screen.dart';
import '../screens/wallet_screen.dart';

Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'القائمة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.location_on, color: Colors.red),
          title: Text('تتبع الرحلة'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TripTrackingScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.wallet, color: Colors.green),
          title: Text('المحفظة'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WalletScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.report_problem, color: Colors.orange),
          title: Text('تقديم شكوى'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ComplaintScreen()),
            );
          },
        ),
      ],
    ),
  );
}
