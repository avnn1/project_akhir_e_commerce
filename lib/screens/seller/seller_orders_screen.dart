import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../main.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final orderService = OrderService();

    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pesanan')),
      body: StreamBuilder<QuerySnapshot>(
        stream: orderService.getSellerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MyApp.primaryColor));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada pesanan masuk', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;
              final status = data['status'];

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
                    Row(
                      children: [
                        Expanded(
                          child: Text('Order: ${orderId.substring(0, 8)}...', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade600)),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Subtotal: Rp ${data['subtotal']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (status == 'PAID')
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.local_shipping_rounded, size: 18),
                          label: const Text('Kirim Barang'),
                          onPressed: () => orderService.updateOrderStatus(orderId, 'SHIPPED'),
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
