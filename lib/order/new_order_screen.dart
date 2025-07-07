import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:warkopos/const/base_url.dart';
import 'package:warkopos/models/kategori_produk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
  int selectedCategoryId = 0;
  bool isLoading = true;
  bool isProcessingTransaction = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  String _generateReceiptText(
    Map<String, dynamic> transaksi,
    double pembayaran,
    double totalAmount,
  ) {
    final now = DateTime.now();
    final formattedDate =
        "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

    String receiptText = """
🧾 WARKOP ACENG
================================
Kode Transaksi: ${transaksi['kode_transaksi']}
Tanggal: $formattedDate
Kasir: ${transaksi['name'] ?? 'Admin'}

DETAIL PEMBELIAN:
--------------------------------
""";

    for (var item in cartItems) {
      receiptText += "${item.produk.namaBarang}\n";
      receiptText +=
          "${item.quantity} x Rp ${item.produk.hargaBarang.toStringAsFixed(0)} = Rp ${item.subtotal.toStringAsFixed(0)}\n\n";
    }

    receiptText += """
--------------------------------
Total Belanja: Rp ${totalAmount.toStringAsFixed(0)}
Pembayaran: Rp ${pembayaran.toStringAsFixed(0)}
Kembalian: Rp ${(pembayaran - totalAmount).toStringAsFixed(0)}
================================

Terima kasih atas kunjungan Anda!
Made with ❤️ by "YANG JAWA JAWA AJA"
""";

    return receiptText;
  }

  Future<void> _sendToWhatsApp(String receiptText, String phoneNumber) async {
    try {
      final encodedText = Uri.encodeComponent(receiptText);
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final whatsappUrl = 'https://wa.me/$cleanedNumber?text=$encodedText';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnackBar('Tidak dapat membuka whatsapp');
      }
    } catch (e) {
      _showSnackBar('Error mengirim ke whatsapp: $e');
    }
  }

  Future<void> _sendToEmail(String receiptText, String email) async {
    try {
      final emailUrl =
          'mailto:$email?subject=Struk Pembayaran&body=${Uri.encodeComponent(receiptText)}';
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
      } else {
        _showSnackBar('Tidak dapat membuka aplikasi email');
      }
    } catch (e) {
      _showSnackBar('Error mengirim email : $e');
    }
  }

  Future<void> _shareReceipt(String receiptText) async {
    try {
      await Share.share(receiptText, subject: 'Struk Pembayaran');
    } catch (e) {
      _showSnackBar('Error sharing struk: $e');
    }
  }

  void _showContactDialog(
    Map<String, dynamic> transaksi,
    double pembayaran,
    double totalAmount,
  ) {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Kirim Struk ke Pembeli'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nomor WhatsApp',
                    prefixText: '+62 ',
                    hintText: '812345678',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (Opsional)',
                    hintText: 'customer@email.com',
                    border: OutlineInputBorder(),
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
                  final receiptText = _generateReceiptText(
                    transaksi,
                    pembayaran,
                    totalAmount,
                  );

                  if (phoneController.text.isNotEmpty) {
                    _sendToWhatsApp(receiptText, '62${phoneController.text}');
                  }

                  if (emailController.text.isNotEmpty) {
                    _sendToEmail(receiptText, emailController.text);
                  }

                  Navigator.pop(context);
                },
                child: Text('Kirim'),
              ),
            ],
          ),
    );
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
          final List<Produk> fetchedProducts =
              (data['data'] as List)
                  .map((item) => Produk.fromJson(item))
                  .toList();

          // for (var product in fetchedProducts) {
          //   print(
          //     'DEBUG: Produk ${product.namaBarang} - Harga: ${product.hargaBarang}',
          //   );
          //   if (product.hargaBarang <= 0) {
          //     print(
          //       'WARNING: Produk ${product.namaBarang} memiliki harga 0 atau negatif!',
          //     );
          //   }
          // }

          setState(() {
            products = fetchedProducts;
          });
        }
      }
    } catch (e) {
      // print('Error fetching products: $e');
      throw Exception('Error Fetching Produk: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseUrl.baseUrl}/list_kategori'),
        // Uri.parse('${BaseUrl.baseNgrok}/list_kategori'),
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
      // print('Error fetching categories: $e');
      // throw Exception('Error fetching categories: $e');
      _showSnackBar('Error Fetching categories : $e');
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
    // print('DEBUG: Menambahkan produk ke cart: ${produk.namaBarang}');
    // print('DEBUG: Harga produk: ${produk.hargaBarang}');
    // print('DEBUG: Stok produk: ${produk.stok}');

    setState(() {
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.produk.id == produk.id,
      );

      if (existingItemIndex != -1) {
        if (cartItems[existingItemIndex].quantity < produk.stok) {
          cartItems[existingItemIndex].quantity++;
          // print(
          //   'DEBUG: Quantity updated: ${cartItems[existingItemIndex].quantity}',
          // );
        } else {
          _showSnackBar('Stok tidak mencukupi');
          return;
        }
      } else {
        final newItem = CartItem(produk: produk);
        cartItems.add(newItem);
        // print('DEBUG: Item baru ditambahkan. Subtotal: ${newItem.subtotal}');
      }
    });

    // print('DEBUG: Total items sekarang: ${cartItems.length}');
    // print('DEBUG: Total amount sekarang: $totalAmount');
    _showSnackBar('${produk.namaBarang} ditambahkan ke keranjang');
  }

  // void _removeFromCart(int productId) {
  //   setState(() {
  //     cartItems.removeWhere((item) => item.produk.id == productId);
  //   });
  // }

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

  // double get totalAmount {
  //   return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  // }

  double get totalAmount {
    final total = cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    // print('DEBUG: Menghitung total amount:');
    // print('DEBUG: Jumlah item di cart: ${cartItems.length}');
    // for (var item in cartItems) {
    //   print(
    //     'DEBUG: ${item.produk.namaBarang} - Qty: ${item.quantity} - Harga: ${item.produk.hargaBarang} - Subtotal: ${item.subtotal}',
    //   );
    // }
    // print('DEBUG: Total amount: $total');
    return total;
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
    // print('DEBUG: Memproses transaksi...');
    // print('DEBUG: Cart items: ${cartItems.length}');
    // print('DEBUG: Total amount: $totalAmount');
    // print('DEBUG: Pembayaran: $pembayaran');

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

    final double savedTotalAmount = totalAmount;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final List<Map<String, dynamic>> details =
          cartItems.map((item) {
            return {
              'barang_id': item.produk.id,
              'qty': item.quantity,
              'harga_satuan': item.produk.hargaBarang.toDouble(),
              'subtotal': item.subtotal.toDouble(),
            };
          }).toList();

      final requestBody = {
        'tanggal': DateTime.now().toIso8601String().split('T')[0],
        'total': savedTotalAmount.toDouble(),
        'user_id': userId,
        'pembayaran': pembayaran.toDouble(),
        'detail': details,
      };

      // print('Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('${BaseUrl.baseUrl}/transaksi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      // print('Response Status: ${response.statusCode}');
      // print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        setState(() {
          cartItems.clear();
        });
        Navigator.pop(context);
        _showTransactionSuccess(data['data'], pembayaran, savedTotalAmount);
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar('Transaksi gagal: ${errorData['message']}');
        // print('Transaksi gagal: ${errorData['message']}');

        // if (errorData.containsKey('errors')) {
        //   print('Validation errors: ${errorData['errors']}');
        // }
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
      // print('Exception: $e');
    } finally {
      setState(() {
        isProcessingTransaction = false;
      });
    }
  }

  void _showTransactionSuccess(
    Map<String, dynamic> transaksi,
    double pembayaran,
    double totalAmount,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.green.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon success
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Title
                  Text(
                    'Transaksi Berhasil!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Pembayaran telah berhasil diproses',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24),

                  // Container detail
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Transaction Code
                        _buildDetailRow(
                          icon: Icons.receipt_long,
                          label: 'Kode Transaksi',
                          value: transaksi['kode_transaksi'],
                          iconColor: Colors.blue,
                        ),

                        Divider(height: 20, color: Colors.grey.shade200),

                        // Total Amount
                        _buildDetailRow(
                          icon: Icons.shopping_cart,
                          label: 'Total Belanja',
                          value: 'Rp ${totalAmount.toStringAsFixed(0)}',
                          iconColor: Colors.orange,
                        ),

                        Divider(height: 20, color: Colors.grey.shade200),

                        // Payment Amount
                        _buildDetailRow(
                          icon: Icons.payment,
                          label: 'Pembayaran',
                          value: 'Rp ${pembayaran.toStringAsFixed(0)}',
                          iconColor: Colors.purple,
                        ),

                        Divider(height: 20, color: Colors.grey.shade200),

                        // Change Amount
                        _buildDetailRow(
                          icon: Icons.monetization_on,
                          label: 'Kembalian',
                          value:
                              'Rp ${(pembayaran - totalAmount).toStringAsFixed(0)}',
                          iconColor: Colors.green,
                          isHighlighted: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Actions buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  () => _shareReceipt(
                                    _generateReceiptText(
                                      transaksi,
                                      pembayaran,
                                      totalAmount,
                                    ),
                                  ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.orange.shade400),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.share,
                                    size: 18,
                                    color: Colors.orange.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  () => _showContactDialog(
                                    transaksi,
                                    pembayaran,
                                    totalAmount, 
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 18),
                                  SizedBox(width: 8),
                                  Text('Kirim'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.print,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Print Struk',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Selesai',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlighted ? 16 : 14,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                  color:
                      isHighlighted
                          ? Colors.green.shade700
                          : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
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
    bool isCalculating = false;
    double kembalian = 0.0;

    if (totalAmount <= 0) {
      _showSnackBar('Total belanja tidak valid. Silakan coba lagi.');
      // print('ERROR: Total amount = $totalAmount saat membuka payment dialog');
      return;
    }

    // print('DEBUG: Membuka payment dialog dengan total: $totalAmount');

    final List<num> presetAmounts =
        [
          totalAmount,
          (totalAmount / 1000).ceil() * 1000,
          (totalAmount / 5000).ceil() * 5000,
          (totalAmount / 10000).ceil() * 10000,
          (totalAmount / 50000).ceil() * 50000,
          (totalAmount / 100000).ceil() * 100000,
        ].where((amount) => amount >= totalAmount).toSet().toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pembayaran',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Rp ${totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        Text(
                          'Pilih Cepat:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: presetAmounts.length,
                            itemBuilder: (context, index) {
                              final amount = presetAmounts[index];
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(
                                    amount == totalAmount
                                        ? 'Pas'
                                        : 'Rp ${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: Colors.blue[50],
                                  side: BorderSide(color: Colors.blue[200]!),
                                  onPressed: () {
                                    paymentController.text = amount
                                        .toStringAsFixed(0);
                                    setState(() {
                                      errorMessage = '';
                                      kembalian = amount - totalAmount;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 16),
                        TextField(
                          controller: paymentController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Pembayaran',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue[600]!,
                                width: 2,
                              ),
                            ),
                            helperText:
                                'Minimal: Rp ${totalAmount.toStringAsFixed(0)}',
                            helperStyle: TextStyle(color: Colors.grey[600]),
                            errorText:
                                errorMessage.isNotEmpty ? errorMessage : null,
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          autofocus: true,
                          onChanged: (value) {
                            final amount = double.tryParse(value) ?? 0;
                            setState(() {
                              errorMessage = '';
                              kembalian =
                                  amount > totalAmount
                                      ? amount - totalAmount
                                      : 0;
                            });
                          },
                        ),

                        SizedBox(height: 16),
                        if (kembalian > 0)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.green[600],
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kembalian',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Rp ${kembalian.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (errorMessage.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[600],
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text('Batal', style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed:
                          isCalculating
                              ? null
                              : () {
                                final pembayaran =
                                    double.tryParse(paymentController.text) ??
                                    0;

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

                                setState(() {
                                  isCalculating = true;
                                });

                                Future.delayed(Duration(milliseconds: 500), () {
                                  Navigator.pop(context);
                                  _processTransaction(pembayaran);
                                });
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child:
                          isCalculating
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Memproses...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payment, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Proses Pembayaran',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
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
