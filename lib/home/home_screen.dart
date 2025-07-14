import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warkopos/auth/profile_screen.dart';
import 'package:warkopos/const/base_url.dart';
import 'package:warkopos/models/transaksi_harian.dart';
import 'package:warkopos/order/new_order_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<TransaksiHariIniResponse?> _futureData;
  String? token;
  bool _isRefreshing = false;

  final List<Map<String, dynamic>> quickActions = [
    {
      'title': 'Pesanan Baru',
      'icon': Icons.add_shopping_cart,
      'color': Colors.blue,
      'route': 'new_order',
    },
    {
      'title': 'Riwayat Pesanan',
      'icon': Icons.history,
      'color': Colors.teal,
      'route': 'history',
    },
    // {
    //   'title': 'Laporan',
    //   'icon': Icons.assessment,
    //   'color': Colors.indigo,
    //   'route': 'report',
    // },
  ];

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    // print(token);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    if (token != null) {
      setState(() {
        _futureData = fetchTotalTransaksiHarian(token!);
      });
    }
  }

  // Method untuk melakukan refresh data
  Future<void> _refreshData() async {
    if (token == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadUserData(); // Refresh token jika diperlukan
      if (token != null) {
        setState(() {
          _futureData = fetchTotalTransaksiHarian(token!);
        });
      }

      // Menunggu sampai data selesai di-fetch
      await _futureData;

      // Menampilkan pesan sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data berhasil diperbarui'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Menampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Gagal memperbarui data'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<TransaksiHariIniResponse?> fetchTotalTransaksiHarian(
    String token,
  ) async {
    try {
      final url = Uri.parse('${BaseUrl.baseUrl}/transaksi/harian');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TransaksiHariIniResponse.fromJson(data);
      } else {
        print('Gagal mengambil data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  void _handleQuickActionTap(String route) {
    switch (route) {
      case 'new_order':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductListScreen()),
        );
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPlaceholderScreen('Riwayat Pesanan'),
          ),
        );
        break;
      case 'report':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPlaceholderScreen('Laporan Penjualan'),
          ),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPlaceholderScreen('Pengaturan'),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Halaman belum tersedia')));
    }
  }

  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Halaman $title',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sedang dalam pengembangan',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warkop Aceng',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Text(
            //   'Sistem Kasir',
            //   style: TextStyle(color: Colors.grey[600], fontSize: 12),
            // ),
          ],
        ),
        actions: [
          // Tombol refresh
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                onPressed: _isRefreshing ? null : _refreshData,
                icon:
                    _isRefreshing
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        )
                        : Icon(Icons.refresh, color: Colors.green),
                tooltip: 'Refresh Data',
              ),
            ),
          ),
          // Tombol profile
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                icon: Icon(Icons.person, color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: Colors.orange[300],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Selamat Datang!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_isRefreshing)
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Siap melayani pelanggan hari ini',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Gunakan FutureBuilder untuk menampilkan data dari API
                    FutureBuilder<TransaksiHariIniResponse?>(
                      future: _futureData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Pesanan Hari Ini',
                                  '...',
                                  Icons.shopping_cart,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Total Penjualan',
                                  '...',
                                  Icons.monetization_on,
                                ),
                              ),
                            ],
                          );
                        } else if (snapshot.hasError || snapshot.data == null) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Pesanan Hari Ini',
                                  '0',
                                  Icons.shopping_cart,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Total Penjualan',
                                  'Rp 0',
                                  Icons.monetization_on,
                                ),
                              ),
                            ],
                          );
                        } else {
                          final data = snapshot.data!;
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Pesanan Hari Ini',
                                  '${data.jumlahTransaksi ?? 0}',
                                  Icons.shopping_cart,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Total Penjualan',
                                  'Rp ${data.totalTransaksi ?? 0}',
                                  Icons.monetization_on,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Text(
              //   'Aksi Cepat',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.grey[800],
              //   ),
              // ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: quickActions.length,
                itemBuilder: (context, index) {
                  final action = quickActions[index];
                  return _buildQuickActionCard(action);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductListScreen()),
          );
        },
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Pesanan Baru',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _handleQuickActionTap(action['route']);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: action['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action['icon'], color: action['color'], size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  action['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
