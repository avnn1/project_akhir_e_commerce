import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/buyer_service.dart';
import '../../main.dart';
import 'shop_detail_screen.dart';

class ShopSearchScreen extends StatefulWidget {
  const ShopSearchScreen({super.key});

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen> {
  final BuyerService _buyerService = BuyerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterShops(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> shops = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      shops = shops.where((shop) {
        final name = (shop['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    shops.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
    return shops;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Toko')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama toko...',
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buyerService.getAllShops(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: MyApp.primaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Belum ada toko terdaftar', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final filteredShops = _filterShops(snapshot.data!.docs);

                if (filteredShops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Toko tidak ditemukan', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: filteredShops.length,
                  itemBuilder: (context, index) {
                    final shop = filteredShops[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: MyApp.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.store_rounded, color: MyApp.primaryColor),
                        ),
                        title: Text(shop['name'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Ketuk untuk lihat produk', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ShopDetailScreen(shopId: shop['id'], shopName: shop['name'] ?? 'Toko'),
                          ));
                        },
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
