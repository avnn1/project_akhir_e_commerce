import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_service.dart';
import '../../main.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'buyer_orders_screen.dart';
import 'shop_search_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final BuyerService _buyerService = BuyerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'name_asc';
  String _selectedCategory = 'Semua';

  static const List<String> _categories = [
    'Semua',
    'Elektronik',
    'Fashion',
    'Makanan & Minuman',
    'Kesehatan',
    'Olahraga',
    'Lainnya',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAndSort(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> products = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategory != 'Semua') {
      products = products.where((product) {
        return (product['category'] ?? 'Lainnya') == _selectedCategory;
      }).toList();
    }

    switch (_sortOption) {
      case 'name_asc':
        products.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
        break;
      case 'name_desc':
        products.sort((a, b) => (b['name'] ?? '').toString().toLowerCase().compareTo((a['name'] ?? '').toString().toLowerCase()));
        break;
      case 'price_asc':
        products.sort((a, b) => ((a['price'] ?? 0) as int).compareTo((b['price'] ?? 0) as int));
        break;
      case 'price_desc':
        products.sort((a, b) => ((b['price'] ?? 0) as int).compareTo((a['price'] ?? 0) as int));
        break;
    }

    return products;
  }

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

    return Scaffold(
      backgroundColor: MyApp.surfaceColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.storefront_rounded, color: MyApp.primaryColor, size: 24),
            const SizedBox(width: 10),
            const Text('MarketPlace'),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: () => context.read<AuthService>().logout(),
          ),
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
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'Pembeli',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Buyer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.store_mall_directory_rounded, color: MyApp.primaryColor),
              title: const Text('Cari Toko', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopSearchScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt_long_rounded, color: MyApp.primaryColor),
              title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk yang kamu inginkan...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: MyApp.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: MyApp.primaryColor, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Category Chips
          Container(
            color: Colors.white,
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    )),
                    selected: isSelected,
                    selectedColor: MyApp.primaryColor,
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? MyApp.primaryColor : Colors.transparent),
                    ),
                  ),
                );
              },
            ),
          ),
          // Sorting Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.expand_more_rounded, color: Colors.grey.shade500),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    items: const [
                      DropdownMenuItem(value: 'name_asc', child: Text('Nama A-Z')),
                      DropdownMenuItem(value: 'name_desc', child: Text('Nama Z-A')),
                      DropdownMenuItem(value: 'price_asc', child: Text('Harga Terendah')),
                      DropdownMenuItem(value: 'price_desc', child: Text('Harga Tertinggi')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sortOption = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Product Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buyerService.getAllProducts(),
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
                        Text('Belum ada produk tersedia', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final filteredProducts = _filterAndSort(snapshot.data!.docs);

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Product Image
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Container(
                                color: Colors.grey.shade100,
                                child: (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                                    ? product['image_url'].toString().startsWith('data:image')
                                        ? Image.memory(
                                            base64Decode(product['image_url'].toString().split(',').last),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade300),
                                          )
                                        : Image.network(
                                            product['image_url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade300),
                                          )
                                    : Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          // Product Info
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.3),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${_formatPrice(product['price'] ?? 0)}',
                                    style: TextStyle(
                                      color: MyApp.primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: MyApp.primaryColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      product['category'] ?? 'Lainnya',
                                      style: TextStyle(fontSize: 10, color: MyApp.primaryColor, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 32,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              side: BorderSide(color: MyApp.primaryColor),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                                            child: Icon(Icons.add_shopping_cart_rounded, size: 16, color: MyApp.primaryColor),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        flex: 2,
                                        child: SizedBox(
                                          height: 32,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            onPressed: () async {
                                              if (user != null) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Menyiapkan pembayaran...'), duration: Duration(seconds: 1)),
                                                );
                                                await _buyerService.addToCart(user.uid, product);
                                                final cartSnapshot = await _buyerService.getCartItems(user.uid).first;
                                                final cartItems = cartSnapshot.docs;
                                                int subtotal = 0;
                                                for (var doc in cartItems) {
                                                  final data = doc.data() as Map<String, dynamic>;
                                                  subtotal += (data['price'] as int) * (data['qty'] as int);
                                                }
                                                if (mounted) {
                                                  Navigator.push(context, MaterialPageRoute(
                                                    builder: (_) => CheckoutScreen(cartItems: cartItems, subtotal: subtotal),
                                                  ));
                                                }
                                              }
                                            },
                                            child: const Text('Beli'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
