import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Untuk Buyer
  Stream<QuerySnapshot> getBuyerOrders(String buyerId) {
    return _firestore
        .collection('orders')
        .where('buyer_id', isEqualTo: buyerId)
        // .orderBy('created_at', descending: true) // Dihapus untuk menghindari error composite index
        .snapshots();
  }

  // Untuk Seller (Mengambil order_items yang shop_id nya milik seller)
  // Untuk MVP, kita asumsikan 1 order = 1 toko untuk mempermudah,
  // tapi struktur kita order_items punya shop_id.
  Stream<QuerySnapshot> getSellerOrders(String sellerId) {
    // Karena firebase tidak bisa join query easily,
    // kita asumsikan untuk MVP kita ambil order items by shop_id 
    // tapi lebih ideal mengambil order yang berkaitan. 
    // Untuk demo cepat, kita simpan seller_id di 'orders' saat checkout 
    // (Jika multi-seller 1 checkout, strukturnya harus dipecah per toko).
    // Karena MVP, kita asumsikan buyer_id, seller_id sudah ter-denormalisasi.
    // Namun karena belum, kita akan melakukan query sederhana:
    return _firestore
        .collection('orders')
        .snapshots(); // Untuk demo, kita baca semua lalu filter di UI, TIDAK DISARANKAN UNTUK PRODUKSI.
  }

  // Seller proses pesanan
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  // Buyer terima barang -> Memicu Escrow ke Saldo Seller
  Future<void> completeOrder(String orderId, String sellerId, int subtotal) async {
    // 1. Update status order
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'COMPLETED',
    });

    // 2. Hitung komisi (Misal 5%)
    double commissionRate = 0.05;
    int commission = (subtotal * commissionRate).toInt();
    int sellerEarning = subtotal - commission;

    // 3. Update / Create Seller Balance
    final balanceRef = _firestore.collection('seller_balances').doc(sellerId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(balanceRef);
      if (!snapshot.exists) {
        transaction.set(balanceRef, {
          'available_balance': sellerEarning,
          'pending_balance': 0,
        });
      } else {
        int currentBalance = snapshot.data()?['available_balance'] ?? 0;
        transaction.update(balanceRef, {
          'available_balance': currentBalance + sellerEarning,
        });
      }

      // 4. Catat ke Ledger
      final ledgerRef = _firestore.collection('ledger_entries').doc();
      transaction.set(ledgerRef, {
        'order_id': orderId,
        'seller_id': sellerId,
        'type': 'SELLER_EARNING',
        'amount': sellerEarning,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // Seller tarik saldo
  Future<void> requestWithdraw(String sellerId, int amount, String destination) async {
    final balanceRef = _firestore.collection('seller_balances').doc(sellerId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(balanceRef);
      if (!snapshot.exists) throw Exception("Saldo tidak ditemukan");

      int currentBalance = snapshot.data()?['available_balance'] ?? 0;
      if (currentBalance < amount) {
        throw Exception("Saldo tidak mencukupi");
      }

      // Potong saldo
      transaction.update(balanceRef, {
        'available_balance': currentBalance - amount,
      });

      // Catat withdrawal request
      final wdRef = _firestore.collection('withdrawals').doc();
      transaction.set(wdRef, {
        'seller_id': sellerId,
        'amount': amount,
        'destination': destination,
        'status': 'PROCESSING', // Langsung diproses oleh Mock API
        'created_at': FieldValue.serverTimestamp(),
      });
    });

    // Mock API Disbursement Delay
    await Future.delayed(const Duration(seconds: 3));
    // Update status to SUCCESS
    final wDocs = await _firestore.collection('withdrawals')
      .where('seller_id', isEqualTo: sellerId)
      .where('amount', isEqualTo: amount)
      .get();
    
    if (wDocs.docs.isNotEmpty) {
      await _firestore.collection('withdrawals').doc(wDocs.docs.first.id).update({
        'status': 'SUCCESS'
      });
    }
  }

  // Ambil saldo
  Stream<DocumentSnapshot> getSellerBalance(String sellerId) {
    return _firestore.collection('seller_balances').doc(sellerId).snapshots();
  }
}
