import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../main.dart';

class SellerBalanceScreen extends StatefulWidget {
  const SellerBalanceScreen({super.key});

  @override
  State<SellerBalanceScreen> createState() => _SellerBalanceScreenState();
}

class _SellerBalanceScreenState extends State<SellerBalanceScreen> {
  final _amountController = TextEditingController();
  final _destController = TextEditingController();
  bool _isWithdrawing = false;

  String _formatPrice(int price) {
    String s = price.toString();
    String result = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      result = s[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) result = '.$result';
    }
    return result;
  }

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penarikan berhasil diproses!')));
        Navigator.pop(context);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Tarik Saldo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Penarikan',
                  hintText: 'Maks: Rp ${_formatPrice(currentBalance)}',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destController,
                decoration: const InputDecoration(
                  labelText: 'Tujuan Transfer',
                  hintText: 'Contoh: DANA 081234...',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isWithdrawing ? null : () => _requestWithdraw(currentBalance),
                  child: _isWithdrawing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Ajukan Penarikan'),
                ),
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
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MyApp.primaryColor));

          int availableBalance = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            availableBalance = snapshot.data!.get('available_balance') ?? 0;
          }

          return Column(
            children: [
              // Balance Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MyApp.primaryColor, MyApp.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: MyApp.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Saldo Tersedia', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Rp ${_formatPrice(availableBalance)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: MyApp.primaryColor,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                        label: const Text('Tarik Saldo'),
                        onPressed: availableBalance > 0 ? () => _showWithdrawModal(availableBalance) : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Withdrawal History Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text('Riwayat Penarikan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  ],
                ),
              ),

              // Withdrawal History List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('withdrawals').where('seller_id', isEqualTo: user.uid).snapshots(),
                  builder: (context, wdSnapshot) {
                    if (wdSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MyApp.primaryColor));
                    if (wdSnapshot.hasError) return Center(child: Text('Error: ${wdSnapshot.error}'));

                    final docs = wdSnapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Belum ada riwayat penarikan', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }

                    final sortedDocs = docs.toList();
                    sortedDocs.sort((a, b) {
                      final aTime = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                      final bTime = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemCount: sortedDocs.length,
                      itemBuilder: (context, index) {
                        final data = sortedDocs[index].data() as Map<String, dynamic>;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.red.shade50,
                              child: Icon(Icons.arrow_upward_rounded, color: Colors.red.shade400, size: 18),
                            ),
                            title: Text('Ke ${data['destination']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            subtitle: Text('Status: ${data['status'] ?? 'UNKNOWN'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            trailing: Text('- Rp ${_formatPrice(data['amount'] ?? 0)}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade500, fontSize: 14)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
