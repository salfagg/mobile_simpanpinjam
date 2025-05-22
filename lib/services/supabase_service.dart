import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/anggota_model.dart';
import '../models/simpanan_model.dart';
import '../models/pinjaman_model.dart';
import '../models/transaksi_model.dart';
import '../models/simpanan_anggota_summary_model.dart';
import '../models/pinjaman_anggota_summary_model.dart';

class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  Future<List<Anggota>> getAnggotaList() async {
    try {
      final List<Map<String, dynamic>> dataList = await _supabase
          .from('anggota')
          .select()
          .order('nama', ascending: true);

      return dataList.map((item) => Anggota.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getAnggotaList: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat daftar anggota: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on getAnggotaList: $e');
      throw Exception('Terjadi kesalahan umum saat memuat daftar anggota: $e');
    }
  }

  Future<void> addAnggota(Anggota anggota) async {
    try {
      await _supabase.from('anggota').insert(anggota.toMap());
      // Tidak perlu cek response.error, error akan dilempar sebagai PostgrestException
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on addAnggota: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menambah anggota: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on addAnggota: $e');
      throw Exception('Terjadi kesalahan umum saat menambah anggota: $e');
    }
  }

  Future<void> updateAnggota(Anggota anggota) async {
    try {
      await _supabase
          .from('anggota')
          .update(anggota.toMap())
          .eq(
            'id_anggota', // Pastikan nama kolom ini sesuai dengan skema DB Anda
            anggota.id!,
          );
      // Tidak perlu cek response.error
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on updateAnggota: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memperbarui anggota: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on updateAnggota: $e');
      throw Exception('Terjadi kesalahan umum saat memperbarui anggota: $e');
    }
  }

  Future<void> deleteAnggota(String idAnggota) async {
    try {
      await _supabase.from('anggota').delete().eq('id_anggota', idAnggota);
      // Tidak perlu cek response.error
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on deleteAnggota: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menghapus anggota: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on deleteAnggota: $e');
      throw Exception('Terjadi kesalahan umum saat menghapus anggota: $e');
    }
  }

  Future<List<Pinjaman>> getPinjamanList() async {
    try {
      final List<Map<String, dynamic>> dataList = await _supabase
          .from('pinjaman')
          .select('*, anggota:id_anggota(nama)')
          .order('tanggal_pinjaman', ascending: false);

      return dataList.map((item) => Pinjaman.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getPinjamanList: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat daftar pinjaman: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on getPinjamanList: $e');
      throw Exception('Terjadi kesalahan umum saat memuat daftar pinjaman: $e');
    }
  }

  Future<Pinjaman> addPinjaman(Pinjaman pinjaman) async {
    // Mengembalikan Pinjaman, bukan Pinjaman?
    try {
      final Map<String, dynamic> data =
          await _supabase
              .from('pinjaman')
              .insert(pinjaman.toMap())
              .select() // Memastikan data yang diinsert dikembalikan
              .single(); // Mengharapkan satu baris data
      return Pinjaman.fromMap(data);
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on addPinjaman: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menambah pinjaman: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on addPinjaman: $e');
      throw Exception('Terjadi kesalahan umum saat menambah pinjaman: $e');
    }
  }

  Future<Simpanan> addSimpanan(Simpanan simpanan) async {
    // Mengembalikan Simpanan, bukan Simpanan?
    try {
      final Map<String, dynamic> data =
          await _supabase
              .from('simpanan')
              .insert(simpanan.toMap())
              .select() // Memastikan data yang diinsert dikembalikan
              .single(); // Mengharapkan satu baris data
      return Simpanan.fromMap(data);
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on addSimpanan: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menambah simpanan: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on addSimpanan: $e');
      throw Exception('Terjadi kesalahan umum saat menambah simpanan: $e');
    }
  }

  Future<List<Simpanan>> getSimpananList() async {
    try {
      final List<Map<String, dynamic>> dataList = await _supabase
          .from('simpanan')
          .select('*, anggota:id_anggota(nama)')
          .order('tanggal_simpan', ascending: false);

      return dataList.map((item) => Simpanan.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getSimpananList: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat daftar simpanan: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on getSimpananList: $e');
      throw Exception('Terjadi kesalahan umum saat memuat daftar simpanan: $e');
    }
  }

  Future<Transaksi> addTransaksi(Transaksi transaksi) async {
    // Mengembalikan Transaksi, bukan Transaksi?
    try {
      final Map<String, dynamic> data =
          await _supabase
              .from('transaksi')
              .insert(transaksi.toMap())
              .select() // Memastikan data yang diinsert dikembalikan
              .single(); // Mengharapkan satu baris data
      return Transaksi.fromMap(data);
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on addTransaksi: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menambah transaksi: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on addTransaksi: $e');
      throw Exception('Terjadi kesalahan umum saat menambah transaksi: $e');
    }
  }

  Future<List<Transaksi>> getTransaksiList() async {
    try {
      final List<Map<String, dynamic>> dataList = await _supabase
          .from('transaksi')
          .select('*, anggota:id_anggota(nama)')
          .order('tanggal_transaksi', ascending: false);

      return dataList.map((item) => Transaksi.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getTransaksiList: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat daftar transaksi: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on getTransaksiList: $e');
      throw Exception(
        'Terjadi kesalahan umum saat memuat daftar transaksi: $e',
      );
    }
  }

  Future<List<Pinjaman>> getPinjamanAktifAnggota(String idAnggota) async {
    try {
      final List<Map<String, dynamic>> dataList = await _supabase
          .from('pinjaman')
          .select('*, anggota:id_anggota(nama)')
          .eq('id_anggota', idAnggota)
          .neq(
            'status_pinjaman',
            'Lunas',
          ) // Pastikan nama kolom 'status_pinjaman'
          .order('tanggal_pinjaman', ascending: false);

      return dataList.map((item) => Pinjaman.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getPinjamanAktifAnggota: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat pinjaman aktif anggota: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on getPinjamanAktifAnggota: $e');
      throw Exception(
        'Terjadi kesalahan umum saat memuat pinjaman aktif anggota: $e',
      );
    }
  }

  Future<void> updatePinjaman(Pinjaman pinjaman) async {
    try {
      await _supabase
          .from('pinjaman')
          .update(pinjaman.toMap())
          .eq('id_pinjaman', pinjaman.id_pinjaman!);
      // Tidak perlu cek response.error
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on updatePinjaman: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memperbarui pinjaman: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on updatePinjaman: $e');
      throw Exception('Terjadi kesalahan umum saat memperbarui pinjaman: $e');
    }
  }

  Future<Pinjaman?> getPinjamanById(String idPinjaman) async {
    try {
      final Map<String, dynamic>? data = // data bisa null
          await _supabase
              .from('pinjaman')
              .select('*, anggota:id_anggota(nama)')
              .eq('id_pinjaman', idPinjaman)
              .maybeSingle(); // Menggunakan maybeSingle untuk handle jika tidak ada data
      if (data == null) return null;
      return Pinjaman.fromMap(data);
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getPinjamanById: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat data pinjaman by ID: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on getPinjamanById: $e');
      throw Exception(
        'Terjadi kesalahan umum saat memuat data pinjaman by ID: $e',
      );
    }
  }

  Future<double> getSaldoSimpananAnggota(String idAnggota) async {
    try {
      final List<Map<String, dynamic>> dataList = await _supabase
          .from('simpanan')
          .select('jumlah')
          .eq('id_anggota', idAnggota);

      return dataList.fold<double>(0.0, (
        double previousSum,
        Map<String, dynamic> item,
      ) {
        final dynamic jumlahValue = item['jumlah'];
        if (jumlahValue is num) {
          return previousSum + jumlahValue.toDouble();
        }
        return previousSum;
      });
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getSaldoSimpananAnggota: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menghitung saldo simpanan: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on getSaldoSimpananAnggota: $e');
      throw Exception(
        'Terjadi kesalahan umum saat menghitung saldo simpanan: $e',
      );
    }
  }

  Future<List<Transaksi>> getTransaksiByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final List<Map<String, dynamic>> dataList = await _supabase
          .from('transaksi')
          .select('*, anggota:id_anggota(nama)')
          .gte('tanggal_transaksi', start.toIso8601String().substring(0, 10))
          .lte('tanggal_transaksi', end.toIso8601String().substring(0, 10))
          .order('tanggal_transaksi', ascending: false);

      return dataList.map((item) => Transaksi.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getTransaksiByDateRange: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception(
        'Gagal mengambil transaksi berdasarkan rentang tanggal: ${e.message}',
      );
    } catch (e) {
      print('SupabaseService Generic Exception on getTransaksiByDateRange: $e');
      throw Exception(
        'Terjadi kesalahan umum saat mengambil transaksi berdasarkan rentang tanggal: $e',
      );
    }
  }

  Future<void> deleteTransaksi(String idTransaksi) async {
    // idTransaksi diubah menjadi non-nullable karena sudah ada check di pemanggil
    try {
      await _supabase
          .from('transaksi')
          .delete()
          .eq('id_transaksi', idTransaksi);
      // Tidak perlu cek response.error
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on deleteTransaksi: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menghapus transaksi: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on deleteTransaksi: $e');
      throw Exception('Terjadi kesalahan umum saat menghapus transaksi: $e');
    }
  }

  Future<void> deleteSimpanan(String idSimpanan) async {
    try {
      await _supabase.from('simpanan').delete().eq('id_simpanan', idSimpanan);
      // Tidak perlu cek response.error
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on deleteSimpanan: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menghapus simpanan: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on deleteSimpanan: $e');
      throw Exception('Terjadi kesalahan umum saat menghapus simpanan: $e');
    }
  }

  Future<void> deletePinjaman(String idPinjaman) async {
    try {
      await _supabase.from('pinjaman').delete().eq('id_pinjaman', idPinjaman);
      // Tidak perlu cek response.error
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on deletePinjaman: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal menghapus pinjaman: ${e.message}');
    } catch (e) {
      print('SupabaseService Generic Exception on deletePinjaman: $e');
      throw Exception('Terjadi kesalahan umum saat menghapus pinjaman: $e');
    }
  }

  Future<List<SimpananAnggotaSummary>> getSimpananSummaryPerAnggota() async {
    try {
      final List<Map<String, dynamic>> dataList =
          await _supabase
              .from('v_simpanan_per_anggota') // Query ke VIEW
              .select();

      return dataList
          .map((item) => SimpananAnggotaSummary.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getSimpananSummaryPerAnggota: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat ringkasan simpanan: ${e.message}');
    } catch (e) {
      // Handle other generic errors
      print(
        'SupabaseService Generic Exception on getSimpananSummaryPerAnggota: $e',
      );
      throw Exception(
        'Terjadi kesalahan umum saat mengambil ringkasan simpanan: $e',
      );
    }
  }

  Future<List<PinjamanAnggotaSummary>>
  getPinjamanAktifSummaryPerAnggota() async {
    try {
      final List<Map<String, dynamic>> dataList =
          await _supabase
              .from('v_pinjaman_aktif_per_anggota') // Query ke VIEW
              .select();

      return dataList
          .map((item) => PinjamanAnggotaSummary.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      print(
        'SupabaseService PostgrestException on getPinjamanAktifSummaryPerAnggota: ${e.message}, code: ${e.code}, details: ${e.details}',
      );
      throw Exception('Gagal memuat ringkasan pinjaman aktif: ${e.message}');
    } catch (e) {
      print(
        'SupabaseService Generic Exception on getPinjamanAktifSummaryPerAnggota: $e',
      );
      throw Exception(
        'Terjadi kesalahan saat mengambil ringkasan pinjaman aktif (catch): $e',
      );
    }
  }
}
