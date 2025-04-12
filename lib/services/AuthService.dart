import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ip.dart';
class AuthService {
  // نقطة النهاية الخاصة بتسجيل الدخول
  static const String _loginUrl = '${ips.apiUrl}api/token/';
  // نقطة النهاية الخاصة بالتسجيل
  static const String _registerUrl = '${ips.apiUrl}api/register/';
  // نقطة النهاية الخاصة بتحديث رمز الوصول
  static const String _refreshUrl = '${ips.apiUrl}api/token/refresh/';

  /// دالة تسجيل الدخول:
  /// ترسل بيانات اسم المستخدم وكلمة المرور إلى الـ API، وعند النجاح تحفظ الرموز في SharedPreferences.
  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(_loginUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final tokenData = jsonDecode(response.body);
      // حفظ بيانات المستخدم مع الرموز
      await _saveUserData({
        'username': username,
        'access_token': tokenData['access'],
        'refresh_token': tokenData['refresh'],
      });
      return true;
    }
    return false;
  }

  /// دالة التسجيل:
  /// ترسل بيانات التسجيل إلى الـ API، وعند النجاح تحفظ بيانات المستخدم بما في ذلك الرموز.
  static Future<bool> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse(_registerUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final tokenData = jsonDecode(response.body);
      await _saveUserData({
        'username': username,
        'email': email,
        'access_token': tokenData['access'],
        'refresh_token': tokenData['refresh'],
      });
      return true;
    }
    return false;
  }

  /// دالة لحفظ بيانات المستخدم في SharedPreferences بصيغة JSON
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  /// التحقق من حالة تسجيل الدخول عبر التأكد من وجود بيانات المستخدم
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_data');
  }

  /// دالة تسجيل الخروج: إزالة بيانات المستخدم من SharedPreferences
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  /// دالة للحصول على header للمصادقة باستخدام رمز الوصول
  static Future<Map<String, String>> getAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString == null) {
      return {};
    }
    final userData = jsonDecode(userDataString);
    final token = userData['access_token'];
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// دالة لجلب بيانات المستخدم من SharedPreferences
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString == null) {
      return {};
    }
    return jsonDecode(userDataString);
  }

  /// دالة لتحديث رمز الوصول باستخدام refresh token
  static Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString == null) {
      throw Exception("لا يوجد بيانات مستخدم، يرجى تسجيل الدخول.");
    }
    final userData = jsonDecode(userDataString);
    final refreshToken = userData['refresh_token'];
    if (refreshToken == null) {
      throw Exception("لا يوجد رمز تحديث، يرجى تسجيل الدخول مجددًا.");
    }

    final response = await http.post(
      Uri.parse(_refreshUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      userData['access_token'] = data['access'];
      // في حال تم تحديث رمز التحديث يمكن تحديثه أيضًا:
      // userData['refresh_token'] = data['refresh'];
      await prefs.setString('user_data', jsonEncode(userData));
    } else {
      throw Exception("فشل تحديث الرمز. يرجى تسجيل الدخول مجددًا.");
    }
  }
}
