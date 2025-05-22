class Simpanan {
  String? id_simpanan; // UUID dari DB adalah String di Dart
  String id_anggota;    // UUID dari DB adalah String di Dart
  DateTime tanggal_simpan;
  double jumlah;
  String jenis;
  String? nama_anggota; // Untuk join, opsional

  Simpanan({
    this.id_simpanan,
    required this.id_anggota,
    required this.tanggal_simpan,
    required this.jumlah,
    required this.jenis,
    this.nama_anggota,
  });

  Map<String, dynamic> toMap() {
    return {
      // 'id_simpanan': id_simpanan, // Biasanya tidak dikirim saat insert jika auto-generate
      'id_anggota': id_anggota,
      'tanggal_simpan': tanggal_simpan.toIso8601String().substring(0, 10), // Format YYYY-MM-DD
      'jumlah': jumlah,
      'jenis': jenis,
    };
  }

  factory Simpanan.fromMap(Map<String, dynamic> map) {
    return Simpanan(
      id_simpanan: map['id_simpanan'] as String?,
      id_anggota: map['id_anggota'] as String,
      tanggal_simpan: DateTime.parse(map['tanggal_simpan'] as String),
      jumlah: (map['jumlah'] as num).toDouble(),
      jenis: map['jenis'] as String,
      nama_anggota: map['anggota'] != null ? map['anggota']['nama'] as String? : null,
    );
  }
}
