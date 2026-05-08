import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/seller_service.dart';

class AddProductScreen extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic>? product;

  const AddProductScreen({super.key, required this.shopId, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  static const List<String> _categories = [
    'Elektronik',
    'Fashion',
    'Makanan & Minuman',
    'Kesehatan',
    'Olahraga',
    'Lainnya',
  ];
  String _selectedCategory = 'Lainnya';

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _stockController.text = widget.product!['stock']?.toString() ?? '';
      _selectedCategory = widget.product!['category'] ?? 'Lainnya';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final productData = {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'price': int.parse(_priceController.text.trim()),
          'stock': int.parse(_stockController.text.trim()),
          'category': _selectedCategory,
        };

        if (widget.product == null) {
          await SellerService().addProduct(widget.shopId, productData, _imageFile);
        } else {
          await SellerService().updateProduct(widget.product!['id'], productData, _imageFile, widget.product!['image_url']);
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : (isEdit && widget.product!['image_url'] != null && widget.product!['image_url'].toString().isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.product!['image_url'].toString().startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(widget.product!['image_url'].toString().split(',').last),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade400),
                                    )
                                  : Image.network(
                                      widget.product!['image_url'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade400),
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Tambahkan Foto Produk', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Ketuk untuk memilih foto', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
                validator: (val) => val == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Price & Stock Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga (Rp)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (val) {
                        if (val!.isEmpty) return 'Wajib diisi';
                        if (int.tryParse(val) == null) return 'Harus angka';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (val) {
                        if (val!.isEmpty) return 'Wajib diisi';
                        if (int.tryParse(val) == null) return 'Harus angka';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Produk', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
