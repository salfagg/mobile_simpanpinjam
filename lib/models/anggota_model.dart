class Anggota {
  final String? id;
  final String nama;
  final String alamat;
  final String telepon;
  final String email;
  final DateTime? tanggalMasuk;

  Anggota({
    this.id,
    required this.nama,
    required this.alamat,
    required this.telepon,
    required this.email,
    this.tanggalMasuk,
  });

  factory Anggota.fromMap(Map<String, dynamic> map) {
    return Anggota(
      // Pastikan tipe data dari map sesuai. Jika 'id_anggota' bisa null, int? sudah tepat.
      // Jika 'id_anggota' adalah string (misalnya UUID), ubah tipe 'id' di model.
      id: map['id_anggota'] as String?,
      // Untuk field String non-nullable, berikan nilai default jika map tidak menyediakannya atau null.
      nama: map['nama'] as String? ?? 'Nama Tidak Ada',
      alamat: map['alamat'] as String? ?? 'Alamat Tidak Ada',
      telepon: map['telepon'] as String? ?? 'Telepon Tidak Ada',
      email: map['email'] as String? ?? 'email@tidakada.com',
      // Gunakan DateTime.tryParse untuk parsing tanggal yang lebih aman.
      tanggalMasuk:
          map['tanggal_masuk'] != null
              ? (map['tanggal_masuk'] is String
                  ? DateTime.tryParse(map['tanggal_masuk'] as String)
                  // Jika 'tanggal_masuk' sudah merupakan objek DateTime (jarang dari JSON)
                  : (map['tanggal_masuk'] is DateTime
                      ? map['tanggal_masuk'] as DateTime
                      : null))
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    // 'id' atau 'id_anggota' biasanya tidak dimasukkan ke .toMap() untuk operasi insert,
    // karena seringkali di-generate otomatis oleh database.
    // Untuk update, ID digunakan di klausa .eq() pada service.
    // Jika Anda *perlu* mengirim ID (misalnya, jika ID tidak auto-generate dan Anda set manual),
    // maka Anda bisa menambahkannya di sini, tapi pastikan itu sesuai dengan skema DB Anda.
    // Contoh:
    // final mapData = <String, dynamic>{
    //   if (id != null) 'id_anggota': id, // Hanya jika diperlukan
    //   ...
    // };
    return {
      'nama': nama,
      'alamat': alamat,
      'telepon': telepon,
      'email': email,
      'tanggal_masuk': tanggalMasuk?.toIso8601String(),
    };
  }
}
