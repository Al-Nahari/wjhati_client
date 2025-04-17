import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../screens/trip_tracking_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/modern_chat_list_screen.dart';
import '../services/AuthService.dart';
import '../main.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key, required Map userData}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // تأكد من تحديث التوكن ثم جلب بيانات المستخدم المحفوظة
      await AuthService.refreshToken();
      final data = await AuthService.getUserData();
      setState(() => _userData = data);
    } catch (e) {
      setState(() => _errorMessage = 'فشل في تحميل بيانات المستخدم');
      Fluttertoast.showToast(
        msg: _errorMessage!,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Colors.white24),
            Expanded(child: _buildMenuItems()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyApp.primry, MyApp.primry.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE0E0E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: MyApp.primry)
                  : Text(
                (_userData?['username'] as String? ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: MyApp.primry,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _isLoading
                ? const Text(
              'جاري التحميل...',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData?['username'] as String? ?? 'مستخدم',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _userData?['email'] as String? ?? 'لا يوجد بريد إلكتروني',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        _buildMenuItem(
          icon: Icons.directions_car_filled,
          title: 'تتبع الرحلات',
          route: const BookingsPage(),
        ),
        _buildMenuItem(
          icon: Icons.account_balance_wallet,
          title: 'المحفظة',
          route: const WalletPage(),
        ),
        _buildMenuItem(
          icon: Icons.support_agent,
          title: 'الدعم الفني',
          route: const ChatListScreen(),
        ),
        const Divider(height: 40, indent: 20, endIndent: 20),
        _buildMenuItem(
          icon: Icons.logout,
          title: 'تسجيل الخروج',
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? route,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: MyApp.primry.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isLogout ? Colors.redAccent : MyApp.primry),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isLogout ? Colors.redAccent : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade500,
        ),
        onTap: () async {
          Navigator.pop(context);
          if (isLogout) {
            await AuthService.logout();
            Navigator.pushReplacementNamed(context, '/Login');
          } else if (route != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => route));
          }
        },
      ),
    );
  }
}
