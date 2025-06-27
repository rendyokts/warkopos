import 'package:flutter/material.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> orderItems = [];
  double totalAmount = 0.0;

  final List<Map<String, dynamic>> menuCategories = [
    {'title': 'Kopi', 'icon': Icons.local_cafe, 'color': Colors.brown},
    {'title': 'Teh', 'icon': Icons.emoji_food_beverage, 'color': Colors.green},
    {'title': 'Makanan', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'title': 'Snack', 'icon': Icons.bakery_dining, 'color': Colors.purple},
  ];

  final Map<String, List<Map<String, dynamic>>> menuItems = {
    'Kopi': [
      {'name': 'Kopi Tubruk', 'price': 8000, 'image': '☕'},
      {'name': 'Kopi Susu', 'price': 12000, 'image': '☕'},
      {'name': 'Espresso', 'price': 15000, 'image': '☕'},
      {'name': 'Cappuccino', 'price': 18000, 'image': '☕'},
      {'name': 'Latte', 'price': 20000, 'image': '☕'},
      {'name': 'Americano', 'price': 16000, 'image': '☕'},
    ],
    'Teh': [
      {'name': 'Teh Manis', 'price': 5000, 'image': '🍵'},
      {'name': 'Teh Tawar', 'price': 3000, 'image': '🍵'},
      {'name': 'Es Teh', 'price': 6000, 'image': '🧊'},
      {'name': 'Teh Susu', 'price': 8000, 'image': '🍵'},
    ],
    'Makanan': [
      {'name': 'Nasi Goreng', 'price': 25000, 'image': '🍛'},
      {'name': 'Mie Ayam', 'price': 20000, 'image': '🍜'},
      {'name': 'Ayam Bakar', 'price': 30000, 'image': '🍗'},
      {'name': 'Gado-gado', 'price': 18000, 'image': '🥗'},
    ],
    'Snack': [
      {'name': 'Pisang Goreng', 'price': 10000, 'image': '🍌'},
      {'name': 'Tahu Isi', 'price': 8000, 'image': '🥟'},
      {'name': 'Keripik', 'price': 5000, 'image': '🍟'},
      {'name': 'Roti Bakar', 'price': 12000, 'image': '🍞'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: menuCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addToOrder(Map<String, dynamic> item) {
    setState(() {
      int existingIndex = orderItems.indexWhere(
        (orderItem) => orderItem['name'] == item['name'],
      );

      if (existingIndex != -1) {
        orderItems[existingIndex]['quantity']++;
      } else {
        orderItems.add({...item, 'quantity': 1});
      }

      _calculateTotal();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} ditambahkan ke pesanan'),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.brown[800],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.brown[600],
          tabs:
              menuCategories.map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category['icon'], size: 18),
                      const SizedBox(width: 8),
                      Text(category['title']),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  menuCategories.map((category) {
                    final items = menuItems[category['title']] ?? [];
                    return _buildMenuGrid(items, category['color']);
                  }).toList(),
            ),
          ),
          if (orderItems.isNotEmpty) _buildOrderSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(List<Map<String, dynamic>> items, Color categoryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMenuItem(item, categoryColor);
        },
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, Color categoryColor) {
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
          onTap: () => _addToOrder(item),
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
                  child: Center(
                    child: Text(
                      item['image'],
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
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

          // Header
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
                onPressed: () => _addToOrder(item),
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
}
