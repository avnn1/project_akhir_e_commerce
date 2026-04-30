import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan semua produk yang aktif
  Stream<QuerySnapshot> getAllProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Menambahkan produk ke keranjang
  Future<void> addToCart(String userId, Map<String, dynamic> product) async {
    final cartRef = _firestore.collection('users').doc(userId).collection('cart');
    
    // Cek apakah produk sudah ada di keranjang
    final existingItem = await cartRef.where('product_id', isEqualTo: product['id']).get();
    
    if (existingItem.docs.isNotEmpty) {
      // Update quantity
      final docId = existingItem.docs.first.id;
      final currentQty = existingItem.docs.first.data()['qty'] ?? 1;
      await cartRef.doc(docId).update({'qty': currentQty + 1});
    } else {
      // Tambah item baru
      await cartRef.add({
        'product_id': product['id'],
        'shop_id': product['shop_id'],
        'name': product['name'],
        'price': product['price'],
        'image_url': product['image_url'],
        'qty': 1,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  // Mendapatkan isi keranjang
  Stream<QuerySnapshot> getCartItems(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots();
  }

  // Update quantity keranjang
  Future<void> updateCartQty(String userId, String cartId, int newQty) async {
    if (newQty <= 0) {
      await _firestore.collection('users').doc(userId).collection('cart').doc(cartId).delete();
    } else {
      await _firestore.collection('users').doc(userId).collection('cart').doc(cartId).update({'qty': newQty});
    }
  }

  // Checkout & Create Order
  Future<String> checkout(String userId, List<QueryDocumentSnapshot> cartItems, int shippingFee) async {
    int subtotal = 0;
    List<Map<String, dynamic>> items = [];
    
    for (var doc in cartItems) {
      final data = doc.data() as Map<String, dynamic>;
      subtotal += (data['price'] as int) * (data['qty'] as int);
      items.add({
        'product_id': data['product_id'],
        'shop_id': data['shop_id'],
        'name': data['name'],
        'price': data['price'],
        'qty': data['qty'],
      });
    }
    
    int total = subtotal + shippingFee;
    
    // Buat order utama
    final orderRef = await _firestore.collection('orders').add({
      'buyer_id': userId,
      'status': 'WAITING_PAYMENT',
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total': total,
      'created_at': FieldValue.serverTimestamp(),
    });
    
    // Simpan order items
    for (var item in items) {
      await _firestore.collection('order_items').add({
        'order_id': orderRef.id,
        ...item,
      });
    }
    
    // Kosongkan keranjang
    for (var doc in cartItems) {
      await _firestore.collection('users').doc(userId).collection('cart').doc(doc.id).delete();
    }
    
    return orderRef.id;
  }
}
