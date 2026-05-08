import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  final FirebaseStorage _storage = FirebaseStorage.instance; // Tidak dipakai lagi untuk gambar produk

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

  // Daftar toko (1 seller = 1 toko)
  Future<void> createShop(String sellerId, String shopName) async {
    // Cek apakah seller sudah punya toko
    final existing = await _firestore
        .collection('shops')
        .where('seller_id', isEqualTo: sellerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Anda sudah memiliki toko. Setiap akun hanya boleh memiliki 1 toko.');
    }

    await _firestore.collection('shops').add({
      'seller_id': sellerId,
      'name': shopName,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Tambah produk dengan gambar (diubah ke Base64 untuk simpan di Firestore)
  Future<void> addProduct(String shopId, Map<String, dynamic> productData, File? imageFile) async {
    String? imageUrl;

    // Jika ada gambar, ubah ke Base64 (Maksimal 1MB untuk Firestore)
    if (imageFile != null) {
      try {
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      } catch (e) {
        debugPrint('Error converting image: $e');
        throw Exception('Gagal memproses gambar: $e');
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

    // Jika ada gambar baru, ubah ke Base64
    if (imageFile != null) {
      try {
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      } catch (e) {
        debugPrint('Error converting image: $e');
        throw Exception('Gagal memproses gambar: $e');
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
