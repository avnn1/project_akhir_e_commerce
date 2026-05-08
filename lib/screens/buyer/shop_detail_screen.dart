import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_service.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';

class ShopDetailScreen extends StatelessWidget {
  final String shopId;
  final String shopName;

  const ShopDetailScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final buyerService = BuyerService();

    return Scaffold(
      appBar: AppBar(
        title: Text(shopName),
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
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: buyerService.getProductsByShopId(shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Toko ini belum memiliki produk.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
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
                                      await buyerService.addToCart(user.uid, product);
                                      if (context.mounted) {
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
                                      
                                      await buyerService.addToCart(user.uid, product);
                                      
                                      final cartSnapshot = await buyerService.getCartItems(user.uid).first;
                                      final cartItems = cartSnapshot.docs;
                                      
                                      int subtotal = 0;
                                      for (var doc in cartItems) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        subtotal += (data['price'] as int) * (data['qty'] as int);
                                      }
                                      
                                      if (context.mounted) {
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
