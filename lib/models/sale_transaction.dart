class SaleTransaction {
  final int id;
  final String kodeTransaksi;
  final DateTime tanggal;
  final double total;
  final String? pembayaran;
  final int userId;

  SaleTransaction({
    required this.id,
    required this.kodeTransaksi,
    required this.tanggal,
    required this.total,
    required this.pembayaran,
    required this.userId,

  });

  factory SaleTransaction.fromJson(Map<String, dynamic> json) {
    return SaleTransaction(
      id: json['id'],
      kodeTransaksi: json['kode_transaksi'],
      tanggal: DateTime.parse(json['tanggal']),
      total: (json['total'] as num).toDouble(),
      pembayaran: json['pembayaran']?.toString(),
      userId: json['user_id'],
    );
  }
}


  