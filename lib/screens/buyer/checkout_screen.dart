import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_service.dart';
import 'payment_simulation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final int subtotal;

  const CheckoutScreen({super.key, required this.cartItems, required this.subtotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final BuyerService _buyerService = BuyerService();
  int _shippingFee = 15000; // Flat rate for MVP
  bool _isLoading = false;

  void _processCheckout() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthService>().currentUser;
      final orderId = await _buyerService.checkout(user!.uid, widget.cartItems, _shippingFee);
      
      if (mounted) {
        // Redirect to Payment Simulation (Tahap 4)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentSimulationScreen(orderId: orderId, total: widget.subtotal + _shippingFee)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = widget.subtotal + _shippingFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...widget.cartItems.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(data['name']),
                subtitle: Text('${data['qty']} x Rp ${data['price']}'),
                trailing: Text('Rp ${(data['qty'] as int) * (data['price'] as int)}'),
              );
            }),
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            const Text('Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kurir Reguler (Estimasi 2-3 Hari)'),
              trailing: Text('Rp $_shippingFee'),
            ),
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp $total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _processCheckout,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Bayar Sekarang'),
            )
          ],
        ),
      ),
    );
  }
}
