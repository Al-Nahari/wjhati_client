import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/AuthService.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        Fluttertoast.showToast(
          msg: 'تم التسجيل بنجاح',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        // الانتقال إلى الصفحة الرئيسية مع استبدال شاشة التسجيل
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Fluttertoast.showToast(
          msg: 'خطأ أثناء التسجيل',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'خطأ في الاتصال بالخادم',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التسجيل')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // حقل اسم المستخدم
              TextFormField(
                controller: _usernameController,
                validator: (value) =>
                value!.isEmpty ? 'يرجى إدخال اسم المستخدم' : null,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
              ),
              const SizedBox(height: 20),
              // حقل البريد الإلكتروني
              TextFormField(
                controller: _emailController,
                validator: (value) =>
                value!.isEmpty ? 'يرجى إدخال البريد الإلكتروني' : null,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              const SizedBox(height: 20),
              // حقل كلمة المرور
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: (value) =>
                value!.isEmpty ? 'يرجى إدخال كلمة المرور' : null,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text('تسجيل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
