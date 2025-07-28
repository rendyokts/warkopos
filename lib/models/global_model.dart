
class TransaksiModel {
  final int id;
  final String kodeTransaksi;
  final String tanggal;
  final int total;
  final int pembayaran;
  final int userId;
  final String userName;
  final List<TransaksiDetail> details;

  TransaksiModel({
    required this.id,
    required this.kodeTransaksi,
    required this.tanggal,
    required this.total,
    required this.pembayaran,
    required this.userId,
    required this.userName,
    required this.details,
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    return TransaksiModel(
      id: json['id'] ?? 0,
      kodeTransaksi: json['kode_transaksi'] ?? '',
      tanggal: json['tanggal'] ?? '',
      total: json['total'] ?? 0,
      pembayaran: json['pembayaran'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      details:
          (json['details'] as List? ?? [])
              .map((detail) => TransaksiDetail.fromJson(detail))
              .toList(),
    );
  }
}

class TransaksiDetail {
  final int id;
  final int barangId;
  final int qty;
  final int hargaSatuan;
  final int subtotal;
  final Produk produk;

  TransaksiDetail({
    required this.id,
    required this.barangId,
    required this.qty,
    required this.hargaSatuan,
    required this.subtotal,
    required this.produk,
  });

  factory TransaksiDetail.fromJson(Map<String, dynamic> json) {
    return TransaksiDetail(
      id: json['id'] ?? 0,
      barangId: json['barang_id'] ?? 0,
      qty: json['qty'] ?? 0,
      hargaSatuan: json['harga_satuan'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      produk: Produk.fromJson(json['produk'] ?? {}),
    );
  }
}

class Produk {
  final int id;
  final String namaBarang;
  final String hargaBarang;

  Produk({
    required this.id,
    required this.namaBarang,
    required this.hargaBarang,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'] ?? 0,
      namaBarang: json['nama_barang'] ?? '',
      hargaBarang: json['harga_barang'] ?? '0',
    );
  }
}
