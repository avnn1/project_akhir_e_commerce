import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/seller_service.dart';
import '../../main.dart';
import 'add_product_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_balance_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final SellerService _sellerService = SellerService();
  bool _isLoading = true;
  Map<String, dynamic>? _shop;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final shop = await _sellerService.getShopBySellerId(user.uid);
      setState(() {
        _shop = shop;
        _isLoading = false;
      });
    }
  }

  void _createShop() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buka Toko Baru', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masukkan nama toko Anda', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Toko',
                prefixIcon: Icon(Icons.store_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final user = context.read<AuthService>().currentUser;
                try {
                  await _sellerService.createShop(user!.uid, nameController.text);
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadShop();
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Produk', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Navigator.pop(context);
              await _sellerService.deleteProduct(productId);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: MyApp.primaryColor)));
    }

    if (_shop == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          actions: [
            IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => context.read<AuthService>().logout()),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: MyApp.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.store_rounded, size: 48, color: MyApp.primaryColor),
                ),
                const SizedBox(height: 24),
                const Text('Mulai Berjualan!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Buka toko Anda dan mulai jual produk ke ribuan pembeli.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Buka Toko Sekarang', style: TextStyle(fontSize: 16)),
                    onPressed: _createShop,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tampilan Toko Aktif
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: MyApp.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.store_rounded, size: 18, color: MyApp.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_shop!['name'], overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, size: 22), onPressed: () => context.read<AuthService>().logout()),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [MyApp.primaryColor, MyApp.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _shop!['name'] ?? 'Toko Saya',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.shopping_bag_rounded, color: MyApp.primaryColor),
              title: const Text('Kelola Pesanan', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet_rounded, color: MyApp.primaryColor),
              title: const Text('Saldo Penjualan', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerBalanceScreen()));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(shopId: _shop!['id'])));
        },
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Produk', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sellerService.getShopProducts(_shop!['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: MyApp.primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada produk', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Tekan tombol di bawah untuk menambahkan', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final product = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              product['id'] = snapshot.data!.docs[index].id;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56, height: 56,
                      child: (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                          ? product['image_url'].toString().startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(product['image_url'].toString().split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.red),
                                )
                              : Image.network(
                                  product['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.red),
                                )
                          : Container(
                              color: Colors.grey.shade100,
                              child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                            ),
                    ),
                  ),
                  title: Text(product['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${product['price']} • Stok: ${product['stock']}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      if (product['category'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: MyApp.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(product['category'], style: TextStyle(fontSize: 11, color: MyApp.primaryColor, fontWeight: FontWeight.w500)),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_rounded, color: MyApp.primaryColor, size: 20),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddProductScreen(shopId: _shop!['id'], product: product),
                          ));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                        onPressed: () => _deleteProduct(product['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
