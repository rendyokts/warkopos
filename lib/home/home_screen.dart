import 'package:flutter/material.dart';
import 'package:warkopos/auth/profile_screen.dart';
import 'package:warkopos/order/new_order_screen.dart';
// Import halaman-halaman lain yang Anda butuhkan
// import 'package:warkopos/history/history_screen.dart';
// import 'package:warkopos/report/report_screen.dart';
// import 'package:warkopos/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> menuCategories = [
    {
      'title': 'Kopi',
      'icon': Icons.local_cafe,
      'color': Colors.brown,
      'items': 15,
    },
    {
      'title': 'Teh',
      'icon': Icons.emoji_food_beverage,
      'color': Colors.green,
      'items': 8,
    },
    {
      'title': 'Makanan',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'items': 12,
    },
    {
      'title': 'Snack',
      'icon': Icons.bakery_dining,
      'color': Colors.purple,
      'items': 20,
    },
  ];

  final List<Map<String, dynamic>> quickActions = [
    {
      'title': 'Pesanan Baru',
      'icon': Icons.add_shopping_cart,
      'color': Colors.blue,
      'route': 'new_order',
    },
    {
      'title': 'Riwayat',
      'icon': Icons.history,
      'color': Colors.teal,
      'route': 'history',
    },
    {
      'title': 'Laporan',
      'icon': Icons.assessment,
      'color': Colors.indigo,
      'route': 'report',
    },
    {
      'title': 'Pengaturan',
      'icon': Icons.settings,
      'color': Colors.grey,
      'route': 'settings',
    },
  ];

  // Fungsi untuk menangani navigasi berdasarkan route
  void _handleQuickActionTap(String route) {
    switch (route) {
      case 'new_order':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewOrderScreen()),
        );
        break;
      case 'history':
        // Ganti dengan halaman riwayat yang sebenarnya
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPlaceholderScreen('Riwayat Pesanan'),
          ),
        );
        // Uncomment jika sudah ada HistoryScreen
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => HistoryScreen()),
        // );
        break;
      case 'report':
        // Ganti dengan halaman laporan yang sebenarnya
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPlaceholderScreen('Laporan Penjualan'),
          ),
        );
        // Uncomment jika sudah ada ReportScreen
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => ReportScreen()),
        // );
        break;
      case 'settings':
        // Ganti dengan halaman pengaturan yang sebenarnya
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPlaceholderScreen('Pengaturan'),
          ),
        );
        // Uncomment jika sudah ada SettingsScreen
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => SettingsScreen()),
        // );
        break;
      default:
        // Jika route tidak ditemukan, tampilkan snackbar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Halaman belum tersedia')));
    }
  }

  // Widget placeholder untuk halaman yang belum dibuat
  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.brown[600],
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Warkop Aceng',
              style: TextStyle(
                color: Colors.brown[800],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sistem Kasir',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                icon: Icon(Icons.person, color: Colors.brown),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown[400]!, Colors.brown[600]!],
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
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.orange[300], size: 24),
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
                  const SizedBox(height: 8),
                  Text(
                    'Siap melayani pelanggan hari ini',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Pesanan Hari Ini',
                          '24',
                          Icons.shopping_cart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Penjualan',
                          'Rp 450K',
                          Icons.monetization_on,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
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

            // Menu Categories
            // Text(
            //   'Kategori Menu',
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.grey[800],
            //   ),
            // ),
            // const SizedBox(height: 12),

            // GridView.builder(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //     crossAxisCount: 2,
            //     childAspectRatio: 1.2,
            //     crossAxisSpacing: 12,
            //     mainAxisSpacing: 12,
            //   ),
            //   itemCount: menuCategories.length,
            //   itemBuilder: (context, index) {
            //     final category = menuCategories[index];
            //     return _buildCategoryCard(category);
            //   },
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewOrderScreen()),
          );
        },
        backgroundColor: Colors.brown[600],
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Panggil fungsi navigasi dengan route yang sesuai
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

  Widget _buildCategoryCard(Map<String, dynamic> category) {
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
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category['icon'],
                    color: category['color'],
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  category['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${category['items']} item',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
