import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_service.dart';
import '../../main.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final BuyerService _buyerService = BuyerService();

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Belanja')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buyerService.getCartItems(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: MyApp.primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!.docs;
          int subtotal = 0;
          for (var doc in cartItems) {
            final data = doc.data() as Map<String, dynamic>;
            subtotal += (data['price'] as int) * (data['qty'] as int);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final doc = cartItems[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final itemTotal = (data['price'] as int) * (data['qty'] as int);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 64, height: 64,
                              child: (data['image_url'] != null && data['image_url'].toString().isNotEmpty)
                                  ? data['image_url'].toString().startsWith('data:image')
                                      ? Image.memory(
                                          base64Decode(data['image_url'].toString().split(',').last),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.red),
                                        )
                                      : Image.network(data['image_url'], fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.red),
                                        )
                                  : Container(color: Colors.grey.shade100, child: Icon(Icons.image_outlined, color: Colors.grey.shade400)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Rp ${_formatPrice(data['price'])}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Rp ${_formatPrice(itemTotal)}', style: TextStyle(color: MyApp.primaryColor, fontWeight: FontWeight.w700, fontSize: 14)),
                              ],
                            ),
                          ),
                          // Quantity Controls
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => _buyerService.updateCartQty(user.uid, doc.id, data['qty'] - 1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(Icons.remove_rounded, size: 18, color: Colors.grey.shade700),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${data['qty']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                ),
                                InkWell(
                                  onTap: () => _buyerService.updateCartQty(user.uid, doc.id, data['qty'] + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(Icons.add_rounded, size: 18, color: MyApp.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Bottom Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Total', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('Rp ${_formatPrice(subtotal)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: MyApp.primaryColor)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CheckoutScreen(cartItems: cartItems, subtotal: subtotal),
                            ));
                          },
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
