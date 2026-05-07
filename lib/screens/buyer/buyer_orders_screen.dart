import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Belum ada pesanan.'));

          // Sorting manual dari yang terbaru
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['created_at'] as Timestamp?;
            final bTime = bData['created_at'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // descending
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;
              final status = data['status'];
              final subtotal = data['subtotal'];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Order ID: $orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('order_items')
                            .where('order_id', isEqualTo: orderId)
                            .get(),
                        builder: (context, itemSnapshot) {
                          if (!itemSnapshot.hasData) {
                            return const Text('Memuat barang...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12));
                          }
                          final items = itemSnapshot.data!.docs;
                          if (items.isEmpty) return const SizedBox();
                          
                          final itemNames = items.map((i) => '${i['qty']}x ${i['name']}').join('\n');
                          return Text(
                            itemNames,
                            style: const TextStyle(color: Colors.black87),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Total: Rp ${data['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Status: $status', style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: status == 'SHIPPED' 
                    ? ElevatedButton(
                        onPressed: () {
                          // Dummy seller id for MVP
                          orderService.completeOrder(orderId, 'seller_dummy_id', subtotal);
                        },
                        child: const Text('Terima'),
                      )
                    : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAITING_PAYMENT': return Colors.orange;
      case 'PAID': return Colors.blue;
      case 'SHIPPED': return Colors.purple;
      case 'COMPLETED': return Colors.green;
      default: return Colors.grey;
    }
  }
}
