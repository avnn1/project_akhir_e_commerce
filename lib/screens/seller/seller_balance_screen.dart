import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';

class SellerBalanceScreen extends StatefulWidget {
  const SellerBalanceScreen({super.key});

  @override
  State<SellerBalanceScreen> createState() => _SellerBalanceScreenState();
}

class _SellerBalanceScreenState extends State<SellerBalanceScreen> {
  final _amountController = TextEditingController();
  final _destController = TextEditingController();
  bool _isWithdrawing = false;

  void _requestWithdraw(int currentBalance) async {
    int amount = int.tryParse(_amountController.text) ?? 0;
    String dest = _destController.text;

    if (amount <= 0 || amount > currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah tidak valid')));
      return;
    }
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tujuan pencairan kosong')));
      return;
    }

    setState(() => _isWithdrawing = true);
    try {
      final user = context.read<AuthService>().currentUser;
      await OrderService().requestWithdraw(user!.uid, amount, dest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal diproses! (Simulasi sukses)')));
        Navigator.pop(context); // close modal if it was in one
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  void _showWithdrawModal(int currentBalance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tarik Saldo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Jumlah Tarik (Max: Rp $currentBalance)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destController,
                decoration: const InputDecoration(labelText: 'Tujuan (Contoh: DANA 081234...)'),
              ),
              const SizedBox(height: 24),
              StatefulBuilder(
                builder: (context, setStateModal) {
                  return ElevatedButton(
                    onPressed: _isWithdrawing ? null : () {
                      _requestWithdraw(currentBalance);
                    },
                    child: _isWithdrawing ? const CircularProgressIndicator() : const Text('Ajukan Penarikan'),
                  );
                }
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final orderService = OrderService();

    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Saldo Penjualan')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: orderService.getSellerBalance(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          int availableBalance = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            availableBalance = snapshot.data!.get('available_balance') ?? 0;
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                color: Colors.green.shade50,
                child: Column(
                  children: [
                    const Text('Saldo Tersedia', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Rp $availableBalance', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('Tarik Saldo'),
                      onPressed: availableBalance > 0 ? () => _showWithdrawModal(availableBalance) : null,
                    )
                  ],
                ),
              ),
              const Expanded(
                child: Center(child: Text('Riwayat Transaksi akan muncul di sini')),
              )
            ],
          );
        },
      ),
    );
  }
}
