class Transaksi {
  String? id_transaksi; // UUID dari DB adalah String di Dart
  String id_anggota; // UUID dari DB adalah String di Dart
  String jenis_transaksi; // Mengikuti nama kolom di DB
  double jumlah;
  DateTime tanggal_transaksi;
  String? nama_anggota; // Untuk join, opsional

  Transaksi({
    this.id_transaksi,
    required this.id_anggota,
    required this.jenis_transaksi, // Mengikuti nama kolom di DB
    required this.jumlah,
    required this.tanggal_transaksi,
    this.nama_anggota,
  });

  Map<String, dynamic> toMap() {
    return {
      // 'id_transaksi': id_transaksi, // Biasanya tidak dikirim saat insert jika auto-generate
      'id_anggota': id_anggota,
      'jenis_transaksi': jenis_transaksi, // Mengikuti nama kolom di DB
      'jumlah': jumlah,
      'tanggal_transaksi': tanggal_transaksi.toIso8601String().substring(
        0,
        10,
      ), // Format YYYY-MM-DD
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id_transaksi: map['id_transaksi'] as String?,
      id_anggota: _parseString(map, 'id_anggota'),
      jenis_transaksi: _parseString(
        map,
        'jenis_transaksi',
      ), // Mengikuti nama kolom di DB
      jumlah: _parseDouble(map, 'jumlah'),
      tanggal_transaksi: _parseDateTime(map, 'tanggal_transaksi'),
      nama_anggota:
          map['anggota'] != null ? map['anggota']['nama'] as String? : null,
    );
  }

  // Helper methods for robust parsing, similar to Pinjaman model
  static String _parseString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null || value is! String) {
      throw FormatException(
        "Invalid or missing '$key' in Transaksi data (expected String, got ${value?.runtimeType}): $value",
        map,
      );
    }
    return value;
  }

  static double _parseDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null || value is! num) {
      throw FormatException(
        "Invalid or missing '$key' in Transaksi data (expected num, got ${value?.runtimeType}): $value",
        map,
      );
    }
    return (value).toDouble();
  }

  static DateTime _parseDateTime(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null || value is! String) {
      throw FormatException(
        "Invalid or missing '$key' in Transaksi data (expected String for date parsing, got ${value?.runtimeType}): $value",
        map,
      );
    }
    try {
      return DateTime.parse(value);
    } catch (e) {
      throw FormatException(
        "Invalid date format for '$key': $value. Error: $e",
        map,
      );
    }
  }
}
