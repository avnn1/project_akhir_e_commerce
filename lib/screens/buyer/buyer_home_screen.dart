import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_service.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'buyer_orders_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final BuyerService _buyerService = BuyerService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text('Menu Pembeli', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Pesanan Saya'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()));
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buyerService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada produk tersedia.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final productDoc = snapshot.data!.docs[index];
              final product = productDoc.data() as Map<String, dynamic>;
              product['id'] = productDoc.id;

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade200,
                        width: double.infinity,
                        child: (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                            ? product['image_url'].toString().startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(product['image_url'].toString().split(',').last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 64, color: Colors.red),
                                  )
                                : Image.network(
                                    product['image_url'], 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 64, color: Colors.red),
                                  )
                            : const Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${product['price']}',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    if (user != null) {
                                      await _buyerService.addToCart(user.uid, product);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Ditambahkan ke keranjang')),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('+ Keranjang'),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    if (user != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Menyiapkan pembayaran...'), duration: Duration(seconds: 1)),
                                      );
                                      
                                      // 1. Masukkan ke keranjang
                                      await _buyerService.addToCart(user.uid, product);
                                      
                                      // 2. Ambil seluruh isi keranjang terbaru
                                      final cartSnapshot = await _buyerService.getCartItems(user.uid).first;
                                      final cartItems = cartSnapshot.docs;
                                      
                                      // 3. Hitung subtotal
                                      int subtotal = 0;
                                      for (var doc in cartItems) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        subtotal += (data['price'] as int) * (data['qty'] as int);
                                      }
                                      
                                      // 4. Langsung lompat ke Checkout
                                      if (mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CheckoutScreen(
                                              cartItems: cartItems,
                                              subtotal: subtotal,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Beli'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
