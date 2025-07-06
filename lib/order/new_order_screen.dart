import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:warkopos/const/base_url.dart';
import 'package:warkopos/models/kategori_produk.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? token;
  List<Produk> products = [];
  List<Kategori> categories = [];
  List<CartItem> cartItems = [];
  int selectedCategoryId = 0; // 0 untuk semua kategori
  bool isLoading = true;
  bool isProcessingTransaction = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    if (token != null) {
      await Future.wait([_fetchProducts(), _fetchCategories()]);
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseUrl.baseUrl}/list_produk'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            products =
                (data['data'] as List)
                    .map((item) => Produk.fromJson(item))
                    .toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseUrl.baseUrl}/list_kategori'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            categories =
                (data['data'] as List)
                    .map((item) => Kategori.fromJson(item))
                    .toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  List<Produk> get filteredProducts {
    if (selectedCategoryId == 0) {
      return products;
    }
    return products
        .where((product) => product.kategoriId == selectedCategoryId)
        .toList();
  }

  void _addToCart(Produk produk) {
    setState(() {
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.produk.id == produk.id,
      );

      if (existingItemIndex != -1) {
        // Cek stok sebelum menambah
        if (cartItems[existingItemIndex].quantity < produk.stok) {
          cartItems[existingItemIndex].quantity++;
        } else {
          _showSnackBar('Stok tidak mencukupi');
          return;
        }
      } else {
        cartItems.add(CartItem(produk: produk));
      }
    });
    _showSnackBar('${produk.namaBarang} ditambahkan ke keranjang');
  }

  void _removeFromCart(int productId) {
    setState(() {
      cartItems.removeWhere((item) => item.produk.id == productId);
    });
  }

  void _updateCartQuantity(int productId, int newQuantity) {
    setState(() {
      final itemIndex = cartItems.indexWhere(
        (item) => item.produk.id == productId,
      );
      if (itemIndex != -1) {
        if (newQuantity <= 0) {
          cartItems.removeAt(itemIndex);
        } else {
          cartItems[itemIndex].quantity = newQuantity;
        }
      }
    });
  }

  double get totalAmount {
    return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get totalItems {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _processTransaction(double pembayaran) async {
    if (cartItems.isEmpty) {
      _showSnackBar('Keranjang kosong');
      return;
    }

    if (pembayaran < totalAmount) {
      _showSnackBar('Pembayaran tidak mencukupi');
      return;
    }

    setState(() {
      isProcessingTransaction = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      final List<Map<String, dynamic>> details =
          cartItems.map((item) {
            return {
              'barang_id': item.produk.id,
              'qty': item.quantity,
              'harga_satuan': item.produk.hargaBarang,
              'subtotal': item.subtotal,
            };
          }).toList();

      final requestBody = {
        'tanggal': DateTime.now().toIso8601String().split('T')[0],
        'total': totalAmount,
        'user_id': userId,
        'pembayaran': pembayaran,
        'detail': details,
      };

      final response = await http.post(
        Uri.parse('${BaseUrl.baseUrl}/transaksi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          cartItems.clear();
        });
        Navigator.pop(context);
        _showTransactionSuccess(data['data'], pembayaran);
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar('Transaksi gagal: ${errorData['message']}');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
    } finally {
      setState(() {
        isProcessingTransaction = false;
      });
    }
  }

  void _showTransactionSuccess(
    Map<String, dynamic> transaksi,
    double pembayaran,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            icon: Icon(Icons.check_circle, color: Colors.green, size: 60),
            title: Text('Transaksi Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kode Transaksi: ${transaksi['kode_transaksi']}'),
                Text('Total: Rp ${totalAmount.toStringAsFixed(0)}'),
                Text('Pembayaran: Rp ${pembayaran.toStringAsFixed(0)}'),
                Text(
                  'Kembalian: Rp ${(pembayaran - totalAmount).toStringAsFixed(0)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Keranjang Belanja',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                      Divider(),
                      Expanded(
                        child:
                            cartItems.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Keranjang kosong',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: cartItems.length,
                                  itemBuilder: (context, index) {
                                    final item = cartItems[index];
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                item.produk.gambarProduk,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.produk.namaBarang,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Rp ${item.produk.hargaBarang.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    'Subtotal: Rp ${item.subtotal.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    _updateCartQuantity(
                                                      item.produk.id,
                                                      item.quantity - 1,
                                                    );
                                                    setModalState(() {});
                                                  },
                                                  icon: Icon(
                                                    Icons.remove_circle_outline,
                                                  ),
                                                ),
                                                Text(
                                                  '${item.quantity}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    if (item.quantity <
                                                        item.produk.stok) {
                                                      _updateCartQuantity(
                                                        item.produk.id,
                                                        item.quantity + 1,
                                                      );
                                                      setModalState(() {});
                                                    } else {
                                                      _showSnackBar(
                                                        'Stok tidak mencukupi',
                                                      );
                                                    }
                                                  },
                                                  icon: Icon(
                                                    Icons.add_circle_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                      if (cartItems.isNotEmpty) ...[
                        Divider(),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total ($totalItems items)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rp ${totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isProcessingTransaction
                                    ? null
                                    : () => _showImprovedPaymentDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child:
                                isProcessingTransaction
                                    ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      'Bayar Sekarang',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          ),
    );
  }

  void _showImprovedPaymentDialog() {
    final TextEditingController paymentController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Pembayaran'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total: Rp ${totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: paymentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Pembayaran',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                          helperText:
                              'Minimal: Rp ${totalAmount.toStringAsFixed(0)}',
                          errorText:
                              errorMessage.isNotEmpty ? errorMessage : null,
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          // Reset error message ketika user mengetik
                          if (errorMessage.isNotEmpty) {
                            setState(() {
                              errorMessage = '';
                            });
                          }
                        },
                      ),
                      if (errorMessage.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final pembayaran =
                            double.tryParse(paymentController.text) ?? 0;

                        if (pembayaran <= 0) {
                          setState(() {
                            errorMessage =
                                'Masukkan jumlah pembayaran yang valid';
                          });
                          return;
                        }

                        if (pembayaran < totalAmount) {
                          final kurang = totalAmount - pembayaran;
                          setState(() {
                            errorMessage =
                                'Pembayaran kurang Rp ${kurang.toStringAsFixed(0)}';
                          });
                          return;
                        }

                        Navigator.pop(context);
                        _processTransaction(pembayaran);
                      },
                      child: Text('Proses'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Produk'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _showCartBottomSheet,
                icon: Icon(Icons.shopping_cart),
              ),
              if (totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$totalItems',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Filter Kategori
                  Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('Semua'),
                            selected: selectedCategoryId == 0,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategoryId = 0;
                              });
                            },
                          ),
                        ),
                        ...categories.map(
                          (category) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category.nama),
                              selected: selectedCategoryId == category.id,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategoryId = category.id;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Daftar Produk
                  Expanded(
                    child:
                        filteredProducts.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tidak ada produk',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : GridView.builder(
                              padding: EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return Card(
                                  elevation: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                          child: Image.network(
                                            product.gambarProduk,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: double.infinity,
                                                  color: Colors.grey[300],
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.namaBarang,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Rp ${product.hargaBarang.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Stok: ${product.stok}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed:
                                                    product.stok > 0
                                                        ? () =>
                                                            _addToCart(product)
                                                        : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                                ),
                                                child: Text(
                                                  product.stok > 0
                                                      ? 'Tambah'
                                                      : 'Stok Habis',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton:
          totalItems > 0
              ? FloatingActionButton.extended(
                onPressed: _showCartBottomSheet,
                backgroundColor: Colors.blue,
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  'Keranjang ($totalItems)',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : null,
    );
  }
}
