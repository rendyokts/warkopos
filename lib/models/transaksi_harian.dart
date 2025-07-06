class TransaksiHariIniResponse {
  final int jumlahTransaksi;
  final double totalTransaksi;

  TransaksiHariIniResponse({
    required this.jumlahTransaksi,
    required this.totalTransaksi,
  });

  factory TransaksiHariIniResponse.fromJson(Map<String, dynamic> json) {
    return TransaksiHariIniResponse(
      jumlahTransaksi: json['jumlah_transaksi'],
      totalTransaksi: (json['total_transaksi'] as num).toDouble(),
    );
  }
}
