import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

// Model classes
class Kategori {
  final int id;
  final String kodeKategori;
  final String nama;

  Kategori({required this.id, required this.kodeKategori, required this.nama});

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'],
      kodeKategori: json['kode_kategori'],
      nama: json['nama'],
    );
  }
}

class Produk {
  final int id;
  final String hargaBarang;
  final String kodeBarang;
  final String namaBarang;
  final String? gambarProduk;
  final int kategoriId;
  final int stok;
  final String status;

  Produk({
    required this.id,
    required this.hargaBarang,
    required this.kodeBarang,
    required this.namaBarang,
    this.gambarProduk,
    required this.kategoriId,
    required this.stok,
    required this.status,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'],
      hargaBarang: json['harga_barang'],
      kodeBarang: json['kode_barang'],
      namaBarang: json['nama_barang'],
      gambarProduk: json['gambar_produk'],
      kategoriId: json['kategori_id'],
      stok: json['stok'],
      status: json['status'],
    );
  }
}

// API Service
class ApiService {
  static const String baseUrl =
      'https://6241-114-10-66-13.ngrok-free.app/api/mobile'; // Ganti dengan URL API Anda

  static Future<List<Kategori>> getKategoriList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list_kategori'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<Kategori> kategoriList =
              (data['data'] as List)
                  .map((item) => Kategori.fromJson(item))
                  .toList();
          return kategoriList;
        }
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Produk>> getProdukList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list_produk'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<Produk> produkList =
              (data['data'] as List)
                  .map((item) => Produk.fromJson(item))
                  .toList();
          return produkList;
        }
      }
      throw Exception('Failed to load products');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final List<Map<String, dynamic>> orderItems = [];
  double totalAmount = 0.0;

  List<Kategori> kategoriList = [];
  List<Produk> produkList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final kategoriFuture = ApiService.getKategoriList();
      final produkFuture = ApiService.getProdukList();

      final results = await Future.wait([kategoriFuture, produkFuture]);

      setState(() {
        kategoriList = results[0] as List<Kategori>;
        produkList = results[1] as List<Produk>;
        isLoading = false;
      });

      // Initialize tab controller after data is loaded
      if (kategoriList.isNotEmpty) {
        _tabController?.dispose(); // Dispose previous controller if exists
        _tabController = TabController(
          length: kategoriList.length,
          vsync: this,
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Produk> _getProdukByKategori(int kategoriId) {
    return produkList
        .where((produk) => produk.kategoriId == kategoriId)
        .toList();
  }

  void _addToOrder(Produk produk) {
    setState(() {
      int existingIndex = orderItems.indexWhere(
        (orderItem) => orderItem['id'] == produk.id,
      );

      if (existingIndex != -1) {
        orderItems[existingIndex]['quantity']++;
      } else {
        orderItems.add({
          'id': produk.id,
          'name': produk.namaBarang,
          'price':
              produk.hargaBarang, // Anda perlu menambahkan field harga di API
          'image': produk.gambarProduk,
          'quantity': 1,
          'stok': produk.stok,
        });
      }

      _calculateTotal();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produk.namaBarang} ditambahkan ke pesanan'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeFromOrder(int index) {
    setState(() {
      if (orderItems[index]['quantity'] > 1) {
        orderItems[index]['quantity']--;
      } else {
        orderItems.removeAt(index);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in orderItems) {
      total += item['price'] * item['quantity'];
    }
    totalAmount = total;
  }

  void _showOrderSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderSummaryModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan Baru',
              style: TextStyle(
                color: Colors.brown[800],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Pilih menu untuk pelanggan',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (orderItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart, color: Colors.brown[800]),
                    onPressed: _showOrderSummary,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${orderItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.brown[800]),
            onPressed: _loadData,
          ),
        ],
        bottom:
            isLoading || _tabController == null
                ? null
                : PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: TabBar(
                    controller: _tabController!,
                    isScrollable: true,
                    labelColor: Colors.brown[800],
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.brown[600],
                    tabs:
                        kategoriList.map((kategori) {
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getKategoriIcon(kategori.nama), size: 18),
                                const SizedBox(width: 8),
                                Text(kategori.nama),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data...'),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (kategoriList.isEmpty) {
      return const Center(child: Text('Tidak ada kategori tersedia'));
    }

    return Column(
      children: [
        Expanded(
          child:
              _tabController != null
                  ? TabBarView(
                    controller: _tabController!,
                    children:
                        kategoriList.map((kategori) {
                          final produkKategori = _getProdukByKategori(
                            kategori.id,
                          );
                          return _buildMenuGrid(
                            produkKategori,
                            _getKategoriColor(kategori.nama),
                          );
                        }).toList(),
                  )
                  : const Center(child: CircularProgressIndicator()),
        ),
        if (orderItems.isNotEmpty) _buildOrderSummaryBar(),
      ],
    );
  }

  Widget _buildMenuGrid(List<Produk> produkList, Color categoryColor) {
    if (produkList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada produk tersedia',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: produkList.length,
        itemBuilder: (context, index) {
          final produk = produkList[index];
          return _buildMenuItem(produk, categoryColor);
        },
      ),
    );
  }

  Widget _buildMenuItem(Produk produk, Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: produk.stok > 0 ? () => _addToOrder(produk) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      produk.gambarProduk != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              produk.gambarProduk!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                );
                              },
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                );
                              },
                            ),
                          )
                          : Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          ),
                ),
                const SizedBox(height: 12),
                Text(
                  produk.namaBarang,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Harga: ${produk.hargaBarang}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        produk.stok > 0 ? Colors.green[600] : Colors.red[600],
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  'Stok: ${produk.stok}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        produk.stok > 0 ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Tambah Pesanan',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: produk.stok > 0 ? categoryColor : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        produk.stok > 0 ? Icons.add : Icons.block,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${orderItems.length} Item',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'Rp ${totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showOrderSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Lihat Pesanan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ringkasan Pesanan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                final item = orderItems[index];
                return _buildOrderItem(item, index);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Rp ${totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _processOrder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Proses Pesanan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildOrderItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (item['image'] != null)
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: TextStyle(fontSize: 14, color: Colors.brown[600]),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _removeFromOrder(index),
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item['quantity']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Find the product and add to order
                  final produk = produkList.firstWhere(
                    (p) => p.id == item['id'],
                  );
                  _addToOrder(produk);
                },
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.brown[600],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _processOrder() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Text('Pesanan Berhasil'),
              ],
            ),
            content: Text(
              'Pesanan dengan total Rp ${totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} telah diproses.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Helper methods
  IconData _getKategoriIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'semua':
        return Icons.food_bank;
      case 'makanan berat':
        return Icons.restaurant;
      case 'makanan ringan':
      case 'camilan':
        return Icons.bakery_dining;
      case 'minuman ringan':
      case 'minuman':
        return Icons.local_cafe;
      case 'mie':
        return Icons.ramen_dining;
      default:
        return Icons.category;
    }
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'semua':
        return Colors.green;
      case 'makanan berat':
        return Colors.orange;
      case 'makanan ringan':
      case 'camilan':
        return Colors.purple;
      case 'minuman ringan':
      case 'minuman':
        return Colors.blue;
      case 'mie':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
