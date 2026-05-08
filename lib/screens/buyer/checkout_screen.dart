import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_service.dart';
import '../../main.dart';
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
  final int _shippingFee = 15000;
  bool _isLoading = false;

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

  void _processCheckout() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthService>().currentUser;
      final orderId = await _buyerService.checkout(user!.uid, widget.cartItems, _shippingFee);

      if (mounted) {
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order Items
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...widget.cartItems.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final itemTotal = (data['qty'] as int) * (data['price'] as int);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                      Text('${data['qty']} x Rp ${_formatPrice(data['price'])}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Text('Rp ${_formatPrice(itemTotal)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Shipping
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 20, color: MyApp.primaryColor),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kurir Reguler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Estimasi 2-3 hari kerja', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('Rp ${_formatPrice(_shippingFee)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Total
                  Container(
                    decoration: BoxDecoration(
                      color: MyApp.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MyApp.primaryColor.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Rp ${_formatPrice(total)}', style: TextStyle(fontWeight: FontWeight.w700, color: MyApp.primaryColor, fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processCheckout,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Bayar Sekarang', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
