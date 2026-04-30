import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeederService {
  Future<String> seedDatabase() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Buat Akun Seller
      UserCredential sellerCred = await auth.createUserWithEmailAndPassword(
        email: 'seller@test.com',
        password: 'password123',
      );
      String sellerId = sellerCred.user!.uid;

      await firestore.collection('users').doc(sellerId).set({
        'id': sellerId,
        'name': 'Budi Seller',
        'email': 'seller@test.com',
        'role': 'seller',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Buat Toko
      DocumentReference shopRef = await firestore.collection('shops').add({
        'seller_id': sellerId,
        'name': 'Toko Serba Ada',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
      });
      String shopId = shopRef.id;

      // 3. Tambah Produk Mockup
      final products = [
        {
          'shop_id': shopId,
          'name': 'Sepatu Sneakers Pria',
          'description': 'Sepatu sneakers nyaman untuk gaya kasual.',
          'price': 250000,
          'stock': 50,
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'shop_id': shopId,
          'name': 'Tas Ransel Laptop',
          'description': 'Tas ransel anti air muat laptop 15 inch.',
          'price': 150000,
          'stock': 30,
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        },
        {
          'shop_id': shopId,
          'name': 'Jam Tangan Minimalis',
          'description': 'Jam tangan elegan dengan strap kulit asli.',
          'price': 350000,
          'stock': 15,
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        }
      ];

      for (var p in products) {
        await firestore.collection('products').add(p);
      }

      // 4. Buat Akun Buyer
      UserCredential buyerCred = await auth.createUserWithEmailAndPassword(
        email: 'buyer@test.com',
        password: 'password123',
      );
      String buyerId = buyerCred.user!.uid;

      await firestore.collection('users').doc(buyerId).set({
        'id': buyerId,
        'name': 'Andi Pembeli',
        'email': 'buyer@test.com',
        'role': 'buyer',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
      });

      // 5. Logout agar user kembali ke halaman login
      await auth.signOut();

      return "Sukses membuat akun 'seller@test.com' & 'buyer@test.com' beserta barang dagangan!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "Data dummy sudah pernah dibuat! Silakan langsung login dengan 'seller@test.com' atau 'buyer@test.com' (password: password123).";
      }
      return "Error Auth: ${e.message}";
    } catch (e) {
      return "Error: $e";
    }
  }
}
