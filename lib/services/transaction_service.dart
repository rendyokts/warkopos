import 'dart:convert';

import 'package:warkopos/const/base_url.dart';
import 'package:warkopos/models/sale_transaction.dart';
import 'package:warkopos/auth/auth_helper.dart';
import 'package:http/http.dart' as http;

class ApiService {

  // Method untuk mengambil semua transaksi dari rentang tanggal
  static Future<List<SaleTransaction>> getAllTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<SaleTransaction> allTransactions = [];

      // Jika tidak ada tanggal yang diberikan, ambil data dari 30 hari terakhir
      DateTime start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      DateTime end = endDate ?? DateTime.now();

      // Loop untuk setiap tanggal dalam rentang
      for (DateTime date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
        String formattedDate = _formatDate(date);

        try {
          List<SaleTransaction> dailyTransactions = await getTransactionList(tanggal: formattedDate);
          allTransactions.addAll(dailyTransactions);
        } catch (e) {
          print("Error getting transactions for date $formattedDate: $e");
          // Lanjutkan ke tanggal berikutnya meskipun ada error
        }
      }

      return allTransactions;
    } catch (e) {
      throw Exception('Error getting all transactions: $e');
    }
  }

  // Method untuk mengambil transaksi berdasarkan tanggal tertentu
  static Future<List<SaleTransaction>> getTransactionList({String? tanggal}) async {
    try {
      String url = '${BaseUrl.baseUrl}/transaksi/list';
      if (tanggal != null && tanggal.isNotEmpty) {
        url += '?tanggal=$tanggal';
      }

      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: await AuthHelper.getAuthHeaders(),
      );

      print("API Response for date $tanggal: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((item) => SaleTransaction.fromJson(item))
              .toList();
        } else {
          throw Exception('API success false: ${data['message']}');
        }
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Method untuk mengambil transaksi bulan ini
  static Future<List<SaleTransaction>> getThisMonthTransactions() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));

    return await getAllTransactions(startDate: startOfMonth, endDate: endOfMonth);
  }

  // Method untuk mengambil transaksi hari ini
  static Future<List<SaleTransaction>> getTodayTransactions() async {
    DateTime today = DateTime.now();
    return await getAllTransactions(startDate: today, endDate: today);
  }

  // Method untuk mengambil transaksi minggu ini
  static Future<List<SaleTransaction>> getThisWeekTransactions() async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    return await getAllTransactions(startDate: startOfWeek, endDate: endOfWeek);
  }

  // Helper method untuk format tanggal ke string YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Method untuk mengambil transaksi dengan rentang tanggal custom
  static Future<List<SaleTransaction>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await getAllTransactions(startDate: startDate, endDate: endDate);
  }

  // Method untuk mengambil transaksi dengan batasan jumlah hari ke belakang
  static Future<List<SaleTransaction>> getRecentTransactions({int days = 7}) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days));

    return await getAllTransactions(startDate: startDate, endDate: endDate);
  }
}