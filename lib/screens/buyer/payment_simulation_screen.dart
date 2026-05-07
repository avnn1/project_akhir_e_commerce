import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _simulatePayment() async {
    setState(() => _isProcessing = true);
    
    // Simulasi delay gateway
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Dalam implementasi asli, backend (Webhook) yang mengubah ini, bukan frontend.
      // Ini hanya simulasi frontend mengubah langsung karena kita tidak ada backend server khusus saat ini.
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'PAID',
        'paid_at': FieldValue.serverTimestamp(),
      });

      // --- BYPASS ESCROW: Langsung tambah saldo ke penjual saat dibayar ---
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('order_items')
          .where('order_id', isEqualTo: widget.orderId)
          .get();
          
      if (itemsSnapshot.docs.isNotEmpty) {
        // Ambil shop_id dari item pertama (asumsi 1 order = 1 toko untuk MVP)
        final shopId = itemsSnapshot.docs.first['shop_id'];
        
        // Cari UID seller yang memiliki shop_id ini
        final shopSnapshot = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
        final sellerId = shopSnapshot.data()?['seller_id'];

        if (sellerId != null) {
          final balanceRef = FirebaseFirestore.instance.collection('seller_balances').doc(sellerId);
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(balanceRef);
            if (!snapshot.exists) {
              transaction.set(balanceRef, {
                'available_balance': widget.total, // Masukkan full nominal
                'pending_balance': 0,
              });
            } else {
              int currentBalance = snapshot.data()?['available_balance'] ?? 0;
              transaction.update(balanceRef, {
                'available_balance': currentBalance + widget.total,
              });
            }
          });
        }
      }
      // ---------------------------------------------------------------------

      // Simpan log payment event
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
            title: const Text('Pembayaran Berhasil!'),
            content: const Text('Terima kasih. Pesanan Anda akan segera diproses oleh Seller.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Pop until root (BuyerHome)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Kembali ke Beranda'),
              )
            ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Scan QRIS untuk Membayar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Image.asset('assets/images/my qris.jpeg', width: 300, height: 300, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text('Total Tagihan: Rp ${widget.total}', style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Jika sudah transfer, tekan tombol di bawah ini:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : _simulatePayment,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
            child: _isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Saya Sudah Bayar (Simulasi)'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showQris = false),
            child: const Text('Batal / Pilih Metode Lain'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Center(
        child: _showQris
          ? _buildQrisView()
          : _isProcessing 
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses pembayaran...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Total Tagihan', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Rp ${widget.total}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  const Text('Pilih Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: _simulatePayment,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
                      child: const Text('Transfer Bank (Simulasi)'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showQris = true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade500, foregroundColor: Colors.white),
                      child: const Text('Bayar via QRIS / DANA'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
