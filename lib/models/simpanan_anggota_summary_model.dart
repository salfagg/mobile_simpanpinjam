class SimpananAnggotaSummary {
  final String idAnggota;
  final String namaAnggota;
  final double totalSimpanan;

  SimpananAnggotaSummary({
    required this.idAnggota,
    required this.namaAnggota,
    required this.totalSimpanan,
  });

  factory SimpananAnggotaSummary.fromMap(Map<String, dynamic> map) {
    return SimpananAnggotaSummary(
      idAnggota: map['id_anggota'] as String,
      namaAnggota:
          map['nama_anggota'] as String? ??
          map['id_anggota'] as String, // Fallback ke ID jika nama null
      totalSimpanan: (map['total_simpanan'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
