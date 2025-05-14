import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../screens/profile.dart';
import '../screens/trip_tracking_screen.dart';
import '../main.dart';
import '../services/AuthService.dart';
import '../services/ip.dart';
import '../services/notification_provider.dart';
import 'modern_chat_list_screen.dart';
import 'TransfersPage.dart';
import 'home_screen.dart';
int walletID = 0 ;

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _walletData;
  String _errorMessage = '';

  final List<_Service> services = [
    _Service('سجل الرحلات', 'تتبع الرحلات التي طلبتها وحدد مكان السائق', FontAwesomeIcons.mapLocation),
    _Service(' أموالك', 'اخر العمليات المالية التي اجريتها ', FontAwesomeIcons.wallet),
    _Service('بيانات التسجيل', ' بيانات تسجيل الدخول', FontAwesomeIcons.idCard),
    _Service('شكوى / تقييم', 'تواصل معا الدعم لتحسين الخدمة...', FontAwesomeIcons.paperPlane),
  ];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();


  }

  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';

    });

    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();
      final response = await http.get(Uri.parse('${ips.apiUrl}wallets/'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _walletData = data is List && data.isNotEmpty ? data[0] : (data is Map<String, dynamic> ? data : null);
          _isLoading = false;
          if (_walletData == null) _errorMessage = 'لا توجد بيانات صالحة.';
        });
      } else {
        setState(() {
          _errorMessage = 'خطأ: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء الاتصال: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildWalletDetails() {
    if (_walletData == null) {
      return const Center(child: Text('لا توجد بيانات للمحفظة.'));
    }

    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF283E51), Color(0xFF4B79A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Positioned(top: 20, right: 20, child: Icon(Icons.credit_card, size: 50, color: Colors.white30)),
          Positioned(bottom: -20, left: -20, child: _buildCircle()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رقم المحفظة: ${_walletData!['id']} ${walletID = _walletData!['id']
                }', style: _textStyle(16, true)),
                const Spacer(),
                Row(
                  children: [
                    _buildDetailColumn('الرصيد', '${_walletData!['balance']} ${_walletData!['currency']}'),
                    _buildDetailColumn('الحالة', _walletData!['is_locked'] ? 'مقفلة' : 'مفتوحة', isEnd: true),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${_walletData!['created_at']}', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, {bool isEnd = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  TextStyle _textStyle(double size, bool bold) {
    return TextStyle(
      color: Colors.white,
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
  }

  Widget _buildCircle() => Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          // أيقونة الإشعارات + Badge
          Consumer<NotificationProvider>(
            builder: (_, prov, __) {
              return IconButton(
                onPressed: () => Navigator.pushNamed(context, '/Notifications'),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications),
                    if (prov.unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.redAccent,
                          child: Text(
                            prov.unreadCount.toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          // زر التحديث
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchWalletData),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : Column(
        children: [
          SafeArea(child: _buildWalletDetails()),
          SizedBox(height: 15,),
          _buildServiceGrid(),
          _buildBottomNavigation(),
        ],
      ),
    );
  }


  Widget _buildServiceGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.builder(
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (_, i) => _ServiceCard(service: services[i]),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          _buildActionButton("رسائل", FontAwesomeIcons.box, () {}),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(FontAwesomeIcons.mapLocationDot, color: MyApp.primry, size: 30),
          ),
          const SizedBox(width: 20),
          _buildActionButton("رحلة", FontAwesomeIcons.taxi, () {
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: MyApp.primry,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
      ),
      icon: FaIcon(icon, color: Colors.white, size: 18),
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}

class _Service {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool highlighted;
  _Service(this.title, this.subtitle, this.icon, {this.highlighted = false});
}

class _ServiceCard extends StatefulWidget {
  final _Service service;
  const _ServiceCard({required this.service});

  @override
  State<_ServiceCard> createState() => __ServiceCardState();
}

class __ServiceCardState extends State<_ServiceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) => _anim.reverse(),
      onTapCancel: () => _anim.reverse(),
      onTap: () {
        final title = widget.service.title;
        if (title.contains("أموالك")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalletTransfersPage(walletId: walletID),
            ),
          );
        }
        else if (title.contains("سجل الرحلات")) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsScreen()));
        } else if (title.contains("بيانات التسجيل")) {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  UserProfilePage()));
        } else if (title.contains("شكوى") || title.contains("تقييم")) {
          Navigator.push(context, MaterialPageRoute(builder: (_) =>  ModernChatListScreen()));
        }
      },


      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: s.highlighted ? MyApp.accent : MyApp.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(s.icon, size: 28, color: s.highlighted ? MyApp.primry : Colors.white),
              const Spacer(),
              Text(s.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: s.highlighted ? MyApp.primry : Colors.white)),
              const SizedBox(height: 4),
              Text(s.subtitle, style: const TextStyle(fontSize: 12, color: MyApp.textLight)),
            ],
          ),
        ),
      ),
    );
  }
}
