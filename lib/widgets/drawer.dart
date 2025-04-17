import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled5/main.dart';
import '../screens/complaint_screen.dart';
import '../screens/trip_tracking_screen.dart';
import '../screens/wallet_screen.dart';
import '../services/AuthService.dart';
import '../services/ip.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key, required Map userData}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      setState(() => _isLoading = true);
      await AuthService.refreshToken();
      final response = await http.get(
        Uri.parse('${ips.apiUrl}user/'),
        headers: await AuthService.getAuthHeader(),
      );
      _handleResponse(response);
    } catch (e) {
      setState(() => _error = 'فشل في التحميل: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      _userData = data is List ? data.first : data;
    } else {
      throw Exception('خطأ في الخادم: ${response.statusCode}');
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
                _userData?['username']?.toString().substring(0,1) ?? '?',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading ? 'جاري التحميل...' : _userData?['username'] ?? 'مستخدم',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_userData?['email'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      _userData!['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
          color: MyApp.primry,
          route: const BookingsPage(),
        ),
        _buildMenuItem(
          icon: Icons.account_balance_wallet,
          title: 'المحفظة',
          color:MyApp.primry,
          route: const WalletPage(),
        ),
        _buildMenuItem(
          icon: Icons.support_agent,
          title: 'الدعم الفني',
          color: MyApp.primry,
          route: const ModernChatListScreen(),
        ),
        const Divider(height: 40, indent: 20, endIndent: 20),
        _buildMenuItem(
          icon: Icons.logout,
          title: 'تسجيل الخروج',
          color: Colors.redAccent,
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
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
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
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