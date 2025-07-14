import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale_transaction.dart';
import '../services/transaction_service.dart';

class SalesHistoryScreen extends StatefulWidget {
  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<SaleTransaction> transactions = [];
  bool isLoading = false;
  String selectedFilter = 'today'; // Default filter
  String? selectedDate; // untuk custom date

  @override
  void initState() {
    super.initState();
    // Set default values dengan proper initialization
    selectedFilter = 'today';
    selectedDate = null;
    loadTransactions();
  }

  void loadTransactions({String? filter, String? customDate}) async {
    setState(() {
      isLoading = true;
      if (filter != null) {
        selectedFilter = filter;
        // Reset selectedDate jika bukan custom filter
        if (filter != 'custom') {
          selectedDate = null;
        }
      }
      if (customDate != null) {
        selectedDate = customDate;
        selectedFilter = 'custom';
      }
    });

    try {
      List<SaleTransaction> result = [];

      switch (selectedFilter) {
        case 'today':
          result = await ApiService.getTodayTransactions();
          break;
        case 'week':
          result = await ApiService.getThisWeekTransactions();
          break;
        case 'month':
          result = await ApiService.getThisMonthTransactions();
          break;
        case 'recent':
          result = await ApiService.getRecentTransactions(days: 7);
          break;
        case 'all':
          result = await ApiService.getAllTransactions();
          break;
        case 'custom':
          if (selectedDate != null && selectedDate!.isNotEmpty) {
            result = await ApiService.getTransactionList(tanggal: selectedDate);
          } else {
            // Jika tidak ada tanggal yang dipilih, tampilkan hari ini sebagai fallback
            result = await ApiService.getTodayTransactions();
            selectedFilter = 'today';
          }
          break;
        default:
          result = await ApiService.getTodayTransactions();
      }

      setState(() {
        transactions = result;
      });
    } catch (e) {
      print("Error loading transactions: $e"); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat data: $e"),
          backgroundColor: Colors.red,
        ),
      );
      // Set empty list jika error
      setState(() {
        transactions = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double get totalSales => transactions.fold(0, (sum, t) => sum + t.total);

  String getFilterDisplayText() {
    switch (selectedFilter) {
      case 'today':
        return 'Hari Ini';
      case 'week':
        return 'Minggu Ini';
      case 'month':
        return 'Bulan Ini';
      case 'recent':
        return '7 Hari Terakhir';
      case 'all':
        return 'Semua Data (30 Hari)';
      case 'custom':
        if (selectedDate != null && selectedDate!.isNotEmpty) {
          try {
            DateTime parsedDate = DateTime.parse(selectedDate!);
            return 'Tanggal: ${DateFormat('dd MMM yyyy').format(parsedDate)}';
          } catch (e) {
            return 'Tanggal: $selectedDate';
          }
        }
        return 'Pilih Tanggal';
      default:
        return 'Hari Ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Penjualan'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () async {
              try {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate != null
                      ? DateTime.tryParse(selectedDate!) ?? DateTime.now()
                      : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(Duration(days: 1)), // Tidak bisa pilih tanggal masa depan
                );

                if (pickedDate != null) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(pickedDate);
                  print("Selected date: $dateStr"); // Debug log
                  loadTransactions(filter: 'custom', customDate: dateStr);
                }
              } catch (e) {
                print("Error picking date: $e"); // Debug log
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error memilih tanggal: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              loadTransactions(filter: value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'today', child: Text('Hari Ini')),
              PopupMenuItem(value: 'week', child: Text('Minggu Ini')),
              PopupMenuItem(value: 'month', child: Text('Bulan Ini')),
              PopupMenuItem(value: 'recent', child: Text('7 Hari Terakhir')),
              PopupMenuItem(value: 'all', child: Text('Semua Data (30 Hari)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Info Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getFilterDisplayText(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${transactions.length} transaksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Total Penjualan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(totalSales),
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Quick Filter Buttons
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('today', 'Hari Ini'),
                _buildFilterChip('week', 'Minggu Ini'),
                _buildFilterChip('month', 'Bulan Ini'),
                _buildFilterChip('recent', '7 Hari'),
                _buildFilterChip('all', 'Semua'),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Transaction List
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data transaksi...'),
                ],
              ),
            )
                : transactions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada data transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'untuk ${getFilterDisplayText().toLowerCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async {
                loadTransactions();
              },
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final trx = transactions[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.receipt,
                          color: Colors.green[600],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        trx.kodeTransaksi,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(trx.tanggal),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          if (trx.pembayaran != null)
                            Text(
                              'Pembayaran: ${trx.pembayaran}',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(trx.total),
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      onTap: () {
                        _showTransactionDetail(trx);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    bool isSelected = selectedFilter == value;
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          if (selected) {
            loadTransactions(filter: value);
          }
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue[700] : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  void _showTransactionDetail(SaleTransaction trx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Detail Transaksi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Transaction details
              _buildDetailRow('Kode Transaksi', trx.kodeTransaksi),
              _buildDetailRow('Tanggal', DateFormat('dd MMM yyyy, HH:mm').format(trx.tanggal)),
              _buildDetailRow('Total', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(trx.total)),
              _buildDetailRow('Pembayaran', trx.pembayaran ?? '-'),
              _buildDetailRow('User ID', trx.userId.toString()),

              SizedBox(height: 20),

              // Close button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}