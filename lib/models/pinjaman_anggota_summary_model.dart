class PinjamanAnggotaSummary {
  final String idAnggota;
  final String namaAnggota;
  final double totalSisaPinjamanAktif;

  PinjamanAnggotaSummary({
    required this.idAnggota,
    required this.namaAnggota,
    required this.totalSisaPinjamanAktif,
  });

  factory PinjamanAnggotaSummary.fromMap(Map<String, dynamic> map) {
    return PinjamanAnggotaSummary(
      idAnggota: map['id_anggota'] as String,
      namaAnggota:
          map['nama_anggota'] as String? ??
          map['id_anggota'] as String, // Fallback ke ID jika nama null
      totalSisaPinjamanAktif:
          (map['total_sisa_pinjaman_aktif'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
