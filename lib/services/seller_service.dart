import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cek apakah seller sudah punya toko
  Future<Map<String, dynamic>?> getShopBySellerId(String sellerId) async {
    final snapshot = await _firestore
        .collection('shops')
        .where('seller_id', isEqualTo: sellerId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    }
    return null;
  }

  // Daftar toko
  Future<void> createShop(String sellerId, String shopName) async {
    await _firestore.collection('shops').add({
      'seller_id': sellerId,
      'name': shopName,
      'status': 'active', // default active for MVP
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Tambah produk dengan gambar
  Future<void> addProduct(String shopId, Map<String, dynamic> productData, File? imageFile) async {
    String? imageUrl;

    // Jika ada gambar, upload ke Firebase Storage dulu
    if (imageFile != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
        final storageRef = _storage.ref().child('product_images/$fileName');
        final uploadTask = await storageRef.putFile(imageFile);
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error uploading image: $e');
        throw Exception('Gagal mengupload gambar. Pastikan Firebase Storage sudah aktif dan aturannya benar: $e');
      }
    }

    await _firestore.collection('products').add({
      'shop_id': shopId,
      ...productData,
      'image_url': imageUrl,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Update produk
  Future<void> updateProduct(String productId, Map<String, dynamic> productData, File? imageFile, String? currentImageUrl) async {
    String? imageUrl = currentImageUrl;

    // Jika ada gambar baru, upload ke Firebase Storage
    if (imageFile != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';
        final storageRef = _storage.ref().child('product_images/$fileName');
        final uploadTask = await storageRef.putFile(imageFile);
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error uploading image: $e');
        throw Exception('Gagal mengupload gambar. Pastikan Firebase Storage sudah aktif dan aturannya benar: $e');
      }
    }

    await _firestore.collection('products').doc(productId).update({
      ...productData,
      'image_url': imageUrl,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Hapus produk
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // Get stream of products for a shop
  Stream<QuerySnapshot> getShopProducts(String shopId) {
    return _firestore
        .collection('products')
        .where('shop_id', isEqualTo: shopId)
        .snapshots();
  }
}
