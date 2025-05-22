class Pinjaman {
  String? id_pinjaman; // UUID dari DB adalah String di Dart
  String id_anggota; // UUID dari DB adalah String di Dart
  DateTime tanggal_pinjaman;
  double jumlah;
  double? bunga;
  String status_pinjaman;
  String? nama_anggota; // Untuk join, opsional

  Pinjaman({
    this.id_pinjaman,
    required this.id_anggota,
    required this.tanggal_pinjaman,
    required this.jumlah,
    this.bunga,
    required this.status_pinjaman,
    this.nama_anggota,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_anggota': id_anggota,
      'tanggal_pinjaman': tanggal_pinjaman.toIso8601String().substring(
        0,
        10,
      ), // Format YYYY-MM-DD
      'jumlah': jumlah,
      'bunga': bunga,
      'status_pinjaman':
          status_pinjaman, // Menggunakan nama kolom DB yang benar
    };
  }

  factory Pinjaman.fromMap(Map<String, dynamic> map) {
    final idAnggota = map['id_anggota'];
    if (idAnggota == null || idAnggota is! String) {
      throw FormatException(
        "Invalid or missing 'id_anggota' in Pinjaman data (expected String, got ${idAnggota?.runtimeType}): $idAnggota",
        map,
      );
    }

    final tanggalPinjamanStr = map['tanggal_pinjaman'];
    if (tanggalPinjamanStr == null || tanggalPinjamanStr is! String) {
      throw FormatException(
        "Invalid or missing 'tanggal_pinjaman' in Pinjaman data (expected String for date parsing, got ${tanggalPinjamanStr?.runtimeType}): $tanggalPinjamanStr",
        map,
      );
    }

    final jumlahNum = map['jumlah'];
    if (jumlahNum == null || jumlahNum is! num) {
      throw FormatException(
        "Invalid or missing 'jumlah' in Pinjaman data (expected num, got ${jumlahNum?.runtimeType}): $jumlahNum",
        map,
      );
    }

    final statusValue =
        map['status_pinjaman']; // Membaca dari kolom DB yang benar
    if (statusValue == null || statusValue is! String) {
      throw FormatException(
        "Invalid or missing 'status_pinjaman' in Pinjaman data (expected String, got ${statusValue?.runtimeType}): $statusValue", // Pesan error disesuaikan
        map,
      );
    }

    return Pinjaman(
      id_pinjaman: map['id_pinjaman'] as String?,
      id_anggota: idAnggota, // Now known to be a String
      tanggal_pinjaman: DateTime.parse(
        tanggalPinjamanStr,
      ), // Now known to be a String
      jumlah: (jumlahNum).toDouble(), // Now known to be a num
      bunga: (map['bunga'] as num?)?.toDouble(),
      status_pinjaman:
          statusValue, // Menggunakan nilai yang sudah divalidasi dari status_pinjaman
      nama_anggota:
          map['anggota'] != null ? map['anggota']['nama'] as String? : null,
    );
  }
}
