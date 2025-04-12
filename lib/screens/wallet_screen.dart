import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/AuthService.dart';
import '../services/ip.dart';
class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _walletData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  /// دالة لاسترجاع بيانات المحفظة من الخادم مع تحديث رمز الوصول أولاً
  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // تحديث رمز الوصول باستخدام refresh token قبل جلب البيانات
      await AuthService.refreshToken();

      // الحصول على header يحتوي على رمز الوصول المحدث
      final headers = await AuthService.getAuthHeader();
      final url = Uri.parse('${ips.apiUrl}wallets/');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          setState(() {
            _walletData = data[0];
            _isLoading = false;
          });
        } else if (data is Map<String, dynamic>) {
          setState(() {
            _walletData = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'تنسيق البيانات من الخادم غير صحيح.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage =
          'خطأ 403: ليس لديك صلاحية للوصول إلى هذه البيانات. تأكد من صحة بيانات التوثيق.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'حدث خطأ: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء الاتصال بالخادم: $e';
        _isLoading = false;
      });
    }
  }

  /// دالة لبناء واجهة عرض بيانات المحفظة بشكل بطاقة ائتمانية أنيقة
  Widget _buildWalletDetails() {
    if (_walletData == null) {
      return const Center(child: Text('لا توجد بيانات للمحفظة.'));
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF283E51),
              Color(0xFF4B79A1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 6),
              blurRadius: 10,
            )
          ],
        ),
        child: Stack(
          children: [
            // أيقونة زخرفية في الزاوية العلوية اليمنى
            Positioned(
              top: 20,
              right: 20,
              child: Icon(
                Icons.credit_card,
                size: 50,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            // شكل دائري زخرفي في الخلفية
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رقم المحفظة
                  Flexible(
                    child: Text(
                      'رقم المحفظة: ${_walletData!['id']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const Spacer(),
                  // بيانات الرصيد والحالة
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الرصيد',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_walletData!['balance']} ${_walletData!['currency']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'الحالة',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _walletData!['is_locked'] ? 'مقفلة' : 'مفتوحة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // عرض تاريخ الإنشاء (يمكنك إضافة تاريخ التحديث إذا رغبت)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_walletData!['created_at']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المحفظة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWalletData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      )
          : _buildWalletDetails(),
    );
  }
}
