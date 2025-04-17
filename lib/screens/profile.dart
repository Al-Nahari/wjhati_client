import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:untitled5/main.dart';
import '../services/AuthService.dart';
import '../services/ip.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _clientData;
  final Color _backgroundColor =  MyApp.textLight;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();

      // جلب البيانات
      final clients = await _fetchClients(headers);
      _clientData = _findClient(clients);
      _userData = await _fetchUserData(headers, _clientData?['user']);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Future<List<dynamic>> _fetchClients(Map<String, String> headers) async {
    final response = await http.get(Uri.parse('${ips.apiUrl}clients/'), headers: headers);
    if (response.statusCode != 200) throw Exception('فشل في جلب العملاء (${response.statusCode})');
    return json.decode(utf8.decode(response.bodyBytes));
  }

  Map<String, dynamic>? _findClient(List<dynamic> clients) {
    try {
      return clients.firstWhere(
            (c) => c['user'] != null,
      ) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchUserData(Map<String, String> headers, dynamic userId) async {
    final response = await http.get(Uri.parse('${ips.apiUrl}user/$userId/'), headers: headers);
    if (response.statusCode != 200) throw Exception('فشل في جلب المستخدم (${response.statusCode})');
    return json.decode(utf8.decode(response.bodyBytes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MyApp.primry, MyApp.primry.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: const Text('الملف الشخصي', style: TextStyle(fontSize: 22)),
              centerTitle: true,
            ),
          ),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: MyApp.primry)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  _errorMessage,
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  onPressed: _loadProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.primry,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildProfileHeader(),
          const SizedBox(height: 30),
          ..._buildInfoCards(),
        ]),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [MyApp.primry, MyApp.primry.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                _userData?['username']?.toString().substring(0,1) ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
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
                  _userData?['username'] ?? 'غير معروف',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color :MyApp.primry,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _userData?['email'] ?? 'لا يوجد بريد إلكتروني',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoCards() {
    final fields = [
      {'icon': Icons.location_city, 'label': 'المدينة', 'value': _clientData?['city']},
      {'icon': Icons.device_hub, 'label': 'رقم الجهاز', 'value': _clientData?['device_id']},
      {'icon': Icons.verified_user, 'label': 'الحالة', 'value': (_clientData?['status'] ?? false) ? 'نشط' : 'غير نشط'},
      {'icon': Icons.date_range, 'label': 'تاريخ الإنشاء', 'value': _formatDate(_clientData?['created_at'])},
    ];

    return fields.map((field) {
      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MyApp.primry.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(field['icon'] as IconData, color: MyApp.primry),
          ),
          title: Text(
            field['label'],
            style: TextStyle(
              fontSize: 16,
              color: MyApp.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            field['value']?.toString() ?? 'غير متوفر',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MyApp.primry,
            ),
          ),
        ),
      );
    }).toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير معروف';
    final dt = DateTime.tryParse(dateString);
    return dt != null
        ? DateFormat.yMMMMd('ar').add_jm().format(dt)
        : dateString;
  }
}