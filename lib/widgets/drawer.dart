import 'package:flutter/material.dart';
import '../screens/complaint_screen.dart';
import '../screens/trip_tracking_screen.dart';
import '../screens/wallet_screen.dart';
import '../services/AuthService.dart';

class AppDrawer extends StatelessWidget {
  /// بيانات المستخدم التي يجب عرضها في رأس القائمة (مثل الاسم والبريد الإلكتروني)
  final Map<String, dynamic> userData;

  const AppDrawer({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // إزالة الـ padding الافتراضي
        padding: EdgeInsets.zero,
        children: [
          _buildUserHeader(),
          _buildDrawerItem(
            icon: Icons.location_on,
            iconColor: Colors.red,
            title: 'تتبع الرحلة',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  BookingsPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.account_balance_wallet,
            iconColor: Colors.green,
            title: 'المحفظة',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  WalletPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.report_problem,
            iconColor: Colors.orange,
            title: 'تقديم شكوى',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  ChatListScreen()),
              );
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            iconColor: Colors.grey,
            title: 'تسجيل الخروج',
            onTap: () async {
              Navigator.pushNamed(context, '/Login');
              await AuthService.logout();
            },
          ),
        ],
      ),
    );
  }

  /// بناء رأس القائمة الذي يعرض بيانات المستخدم
  Widget _buildUserHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(
        userData['username'] ?? 'اسم المستخدم',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(
        userData['email'] ?? 'البريد الإلكتروني',
        style: const TextStyle(fontSize: 14),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          (userData['username'] != null && userData['username'].toString().isNotEmpty)
              ? userData['username'][0].toUpperCase()
              : '',
          style: const TextStyle(fontSize: 40.0, color: Colors.blue),
        ),
      ),
      decoration: const BoxDecoration(
        color: Colors.blue,
      ),
    );
  }

  /// دالة لبناء عنصر من عناصر القائمة مع أيقونة وعنوان وإجراء عند الضغط
  Widget _buildDrawerItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}