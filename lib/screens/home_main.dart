import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../main.dart';


class HomePage extends StatelessWidget {
  // بيانات وهمية للخدمات
  final List<_Service> services = [
    _Service('حول / ارسل', 'ارسال حوالة لعميل خارجي...', FontAwesomeIcons.paperPlane),
    _Service('استقبل أموالك', 'استقبال حوالات من مختلف القنوات', FontAwesomeIcons.wallet),
    _Service('سداد وشحن', 'شحن رصيد وباقات إنترنت وهاتف ثابت', FontAwesomeIcons.mobileAlt),
    _Service('الألعاب', 'اشتري ألعابك المفضلة', FontAwesomeIcons.gamepad),
    _Service('اشتراكات وبطاقات', 'بطاقات هدايا واشتراكات', FontAwesomeIcons.idCard),
    _Service('مواصلات', 'حجز مواصلات عبر Muasalat', FontAwesomeIcons.bus, highlighted: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer جانبي
      drawer: Drawer(
        child: Container(color: MyApp.primry),
      ),
      // AppBar شفاف مع المعلومات
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
        ),
        title: Text('صباح الخير محمد', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          Icon(Icons.remove_red_eye, color: Colors.white70),
          SizedBox(width: 4),
          Text('0.00', style: TextStyle(fontSize: 16)),
          SizedBox(width: 4),
          Text('YER', style: TextStyle(color: MyApp.accent, fontWeight: FontWeight.bold)),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط التحديث
          Container(
            width: double.infinity,
            color: MyApp.cardColor,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'يجب عليك تحديث البيانات',
              style: TextStyle(color: MyApp.textLight),
            ),
          ),
          SizedBox(height: 12),
          // شبكة الخدمات
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: services.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final s = services[index];
                  return _ServiceCard(service: s);
                },
              ),
            ),
          ),
        ],
      ),
      // زر مركزي بارز
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyApp.accent,
        elevation: 6,
        child: Icon(Icons.qr_code_scanner, color: MyApp.primry, size: 32),
        onPressed: () {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // شريط التنقل السفلي مع نوتش للزر المركزي
      bottomNavigationBar: BottomAppBar(
        color: MyApp.cardColor,
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavBarIcon(icon: Icons.more_horiz, onTap: () {}),
              _NavBarIcon(icon: Icons.check_box, onTap: () {}),
              SizedBox(width: 48), // مسافة للـ FAB
              _NavBarIcon(icon: Icons.copy, onTap: () {}),
              _NavBarIcon(icon: Icons.home, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

// نموذج بيانات خدمة
class _Service {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool highlighted;
  _Service(this.title, this.subtitle, this.icon, {this.highlighted = false});
}

// كرت الخدمة مع تأثير ظل وتحريك خفيف عند الضغط
class _ServiceCard extends StatefulWidget {
  final _Service service;
  const _ServiceCard({required this.service});

  @override
  __ServiceCardState createState() => __ServiceCardState();
}

class __ServiceCardState extends State<_ServiceCard> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _anim.forward();
  void _onTapUp(_) => _anim.reverse();

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _anim.reverse(),
      onTap: () {},
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: s.highlighted ? MyApp.accent : MyApp.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(s.icon, size: 28, color: s.highlighted ? MyApp.primry : Colors.white),
              Spacer(),
              Text(
                s.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: s.highlighted ? MyApp.primry : Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                s.subtitle,
                style: TextStyle(fontSize: 12, color: MyApp.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// أيقونة في شريط التنقل السفلي
class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Icon(icon, size: 28, color: Colors.white70),
    );
  }
}
