import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';

class PaymentSimulationScreen extends StatefulWidget {
  final String orderId;
  final int total;

  const PaymentSimulationScreen({super.key, required this.orderId, required this.total});

  @override
  State<PaymentSimulationScreen> createState() => _PaymentSimulationScreenState();
}

class _PaymentSimulationScreenState extends State<PaymentSimulationScreen> {
  bool _isProcessing = false;
  bool _showQris = false;

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

  void _simulatePayment() async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));

    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'PAID',
        'paid_at': FieldValue.serverTimestamp(),
      });

      final itemsSnapshot = await FirebaseFirestore.instance.collection('order_items').where('order_id', isEqualTo: widget.orderId).get();

      if (itemsSnapshot.docs.isNotEmpty) {
        final shopId = itemsSnapshot.docs.first['shop_id'];
        final shopSnapshot = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
        final sellerId = shopSnapshot.data()?['seller_id'];

        if (sellerId != null) {
          final balanceRef = FirebaseFirestore.instance.collection('seller_balances').doc(sellerId);
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(balanceRef);
            if (!snapshot.exists) {
              transaction.set(balanceRef, {'available_balance': widget.total, 'pending_balance': 0});
            } else {
              int currentBalance = snapshot.data()?['available_balance'] ?? 0;
              transaction.update(balanceRef, {'available_balance': currentBalance + widget.total});
            }
          });
        }
      }

      await FirebaseFirestore.instance.collection('payment_events').add({
        'order_id': widget.orderId,
        'event_type': 'SIMULATED_SUCCESS',
        'amount': widget.total,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_rounded, size: 48, color: Colors.green.shade600),
                ),
                const SizedBox(height: 20),
                const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Pesanan Anda akan segera diproses oleh seller.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Kembali ke Beranda'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildQrisView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text('Scan QRIS untuk Membayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/my qris.jpeg', width: 260, height: 260, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: MyApp.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Rp ${_formatPrice(widget.total)}', style: TextStyle(fontSize: 22, color: MyApp.primaryColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Jika sudah transfer, tekan tombol di bawah', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _simulatePayment,
              child: _isProcessing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Saya Sudah Bayar'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showQris = false),
            child: const Text('Pilih Metode Lain'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: _showQris
          ? _buildQrisView()
          : _isProcessing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: MyApp.primaryColor),
                      const SizedBox(height: 20),
                      Text('Memproses pembayaran...', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Amount display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text('Total Tagihan', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('Rp ${_formatPrice(widget.total)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: MyApp.primaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text('Pilih Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      const SizedBox(height: 16),
                      // Transfer Bank
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.account_balance_rounded),
                          label: const Text('Transfer Bank (Simulasi)'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: MyApp.primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _simulatePayment,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // QRIS
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_rounded),
                          label: const Text('Bayar via QRIS / DANA'),
                          onPressed: () => setState(() => _showQris = true),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
