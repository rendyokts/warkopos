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
  final String kodeBarang;
  final String namaBarang;
  final String? gambarProduk;
  final int kategoriId;
  final int stok;
  final String status;

  Produk({
    required this.id,
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
      kodeBarang: json['kode_barang'],
      namaBarang: json['nama_barang'],
      gambarProduk: json['gambar_produk'],
      kategoriId: json['kategori_id'],
      stok: json['stok'],
      status: json['status'],
    );
  }
}
