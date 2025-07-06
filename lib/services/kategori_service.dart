import 'dart:convert';

import 'package:warkopos/const/base_url.dart';
import 'package:warkopos/models/kategori_produk.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<List<Kategori>> getKategoriList() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseUrl.baseUrl}/list_kategori'),
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
        Uri.parse('${BaseUrl.baseUrl}/list_produk'),
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
