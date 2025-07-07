// class Produk {
//   final int id;
//   final String kodeBarang;
//   final String namaBarang;
//   final double hargaBarang;
//   final String gambarProduk;
//   final int kategoriId;
//   final int stok;
//   final String status;

//   Produk({
//     required this.id,
//     required this.kodeBarang,
//     required this.namaBarang,
//     required this.hargaBarang,
//     required this.gambarProduk,
//     required this.kategoriId,
//     required this.stok,
//     required this.status,
//   });

//   factory Produk.fromJson(Map<String, dynamic> json) {
//     return Produk(
//       id: json['id'],
//       kodeBarang: json['kode_barang'],
//       namaBarang: json['nama_barang'],
//       hargaBarang: double.parse(json['harga_barang'].toString()),
//       gambarProduk: json['gambar_produk'],
//       kategoriId: json['kategori_id'],
//       stok: json['stok'],
//       status: json['status'],
//     );
//   }
// }

class Produk {
  final int id;
  final String kodeBarang;
  final String namaBarang;
  final double hargaBarang;
  final String gambarProduk;
  final int kategoriId;
  final int stok;
  final String status;

  Produk({
    required this.id,
    required this.kodeBarang,
    required this.namaBarang,
    required this.hargaBarang,
    required this.gambarProduk,
    required this.kategoriId,
    required this.stok,
    required this.status,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    double harga = 0.0;
    try {
      harga = double.parse(json['harga_barang'].toString());
    } catch (e) {
      // print('ERROR: Gagal parsing harga untuk ${json['nama_barang']}: ${json['harga_barang']}');
      harga = 0.0;
    }

    return Produk(
      id: json['id'],
      kodeBarang: json['kode_barang'],
      namaBarang: json['nama_barang'],
      hargaBarang: harga,
      gambarProduk: json['gambar_produk'],
      kategoriId: json['kategori_id'],
      stok: json['stok'],
      status: json['status'],
    );
  }
}

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

class CartItem {
  final Produk produk;
  int quantity;

  CartItem({required this.produk, this.quantity = 1});

  double get subtotal => produk.hargaBarang * quantity;
}
