import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final BuyerService _buyerService = BuyerService();

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
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Keranjang masih kosong.'));
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
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final doc = cartItems[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return ListTile(
                      leading: SizedBox(
                        width: 50, height: 50,
                        child: data['image_url'] != null
                            ? Image.network(data['image_url'], fit: BoxFit.cover)
                            : const Icon(Icons.image),
                      ),
                      title: Text(data['name']),
                      subtitle: Text('Rp ${data['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _buyerService.updateCartQty(user.uid, doc.id, data['qty'] - 1),
                          ),
                          Text('${data['qty']}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _buyerService.updateCartQty(user.uid, doc.id, data['qty'] + 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total Pembayaran:', style: TextStyle(color: Colors.grey)),
                          Text('Rp $subtotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(cartItems: cartItems, subtotal: subtotal),
                            ),
                          );
                        },
                        child: const Text('Checkout'),
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
