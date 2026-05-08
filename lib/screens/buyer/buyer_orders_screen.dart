import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../main.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

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
    final orderService = OrderService();

    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: StreamBuilder<QuerySnapshot>(
        stream: orderService.getBuyerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MyApp.primaryColor));
          if (snapshot.hasError) return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada pesanan', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['created_at'] as Timestamp?;
            final bTime = bData['created_at'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;
              final status = data['status'];
              final subtotal = data['subtotal'];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text('ID: ${orderId.substring(0, 8)}...', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade600)),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Items
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('order_items').where('order_id', isEqualTo: orderId).get(),
                      builder: (context, itemSnapshot) {
                        if (!itemSnapshot.hasData) return Text('Memuat...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey.shade400));
                        final items = itemSnapshot.data!.docs;
                        if (items.isEmpty) return const SizedBox();
                        return Column(
                          children: items.map((i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('${i['qty']}x ${i['name']}', style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 6),
                    // Total & Action
                    Row(
                      children: [
                        Expanded(
                          child: Text('Total: Rp ${_formatPrice(data['total'] ?? 0)}', style: TextStyle(fontWeight: FontWeight.w700, color: MyApp.primaryColor)),
                        ),
                        if (status == 'SHIPPED')
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                              onPressed: () => orderService.completeOrder(orderId, 'seller_dummy_id', subtotal),
                              child: const Text('Terima Barang', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                      ],
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'WAITING_PAYMENT':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Menunggu Bayar';
        break;
      case 'PAID':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Dibayar';
        break;
      case 'SHIPPED':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        label = 'Dikirim';
        break;
      case 'COMPLETED':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Selesai';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}
