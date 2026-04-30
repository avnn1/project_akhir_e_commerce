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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Gateway (Simulasi)')),
      body: Center(
        child: _isProcessing 
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                    child: const Text('Bayar via Virtual Account'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: _simulatePayment,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade400, foregroundColor: Colors.white),
                    child: const Text('Bayar via DANA (Mock)'),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
