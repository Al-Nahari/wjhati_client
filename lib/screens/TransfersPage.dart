import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/AuthService.dart';
import '../services/ip.dart';
import '../main.dart';

class WalletTransfersPage extends StatefulWidget {
  final int walletId; // المحفظة المرتبطة بالمستخدم

  const WalletTransfersPage({Key? key, required this.walletId}) : super(key: key);

  @override
  State<WalletTransfersPage> createState() => _WalletTransfersPageState();
}

class _WalletTransfersPageState extends State<WalletTransfersPage> {
  bool _isLoading = true;
  List<dynamic> _transfers = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchTransfers();
  }

  Future<void> _fetchTransfers() async {
    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();

      final response = await http.get(
        Uri.parse('${ips.apiUrl}transfers/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final filteredTransfers = data.where((transfer) =>
        transfer['from_wallet'] == widget.walletId).toList();

        setState(() {
          _transfers = filteredTransfers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'فشل في تحميل البيانات: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildTransferCard(Map<String, dynamic> transfer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyApp.primry,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(1, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('المبلغ:', '${transfer['amount']} ر.ي'),
          _buildRow('الحالة:', transfer['status'] == 'pending' ? 'قيد التنفيذ' : 'تمت'),
          _buildRow('إلى المحفظة:', '${transfer['to_wallet']}'),
          _buildRow('تاريخ الإنشاء:', transfer['created_at'].toString().split('T').first),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: MyApp.textLight, fontSize: 14))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold,color: MyApp.textLight,fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عمليات التحويل'),
        backgroundColor: MyApp.primry,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
          : _transfers.isEmpty
          ? const Center(child: Text('لا توجد عمليات تحويل.'))
          : ListView.builder(
        itemCount: _transfers.length,
        itemBuilder: (context, index) =>
            _buildTransferCard(_transfers[index]),
      ),
    );
  }
}
