import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/simpanan_anggota_summary_model.dart'; // Model baru
import '../services/supabase_service.dart';
import 'package:simpan_pinjam/main.dart'; // Untuk akses instance supabase global

class SimpananScreen extends StatefulWidget {
  const SimpananScreen({super.key});

  @override
  State<SimpananScreen> createState() => _SimpananScreenState();
}

class _SimpananScreenState extends State<SimpananScreen> {
  final SupabaseService _supabaseService = SupabaseService(supabase);
  late Future<List<SimpananAnggotaSummary>>
  _simpananSummaryFuture; // Menggunakan Future dengan model baru
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');
  final NumberFormat _currencyFormatter = NumberFormat("#,##0", "id_ID");

  @override
  void initState() {
    super.initState();
    _loadSimpananSummary();
  }

  void _loadSimpananSummary() {
    // Nama method diubah agar lebih deskriptif
    setState(() {
      _simpananSummaryFuture =
          _supabaseService
              .getSimpananSummaryPerAnggota(); // Memanggil method service baru
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Data Simpanan'),
        backgroundColor: const Color(0xFF5409DA), // Warna dari gradasi bawah
        foregroundColor: Colors.white, // Warna teks dan ikon di AppBar
        elevation: 8, // Tambah sedikit bayangan
        shape: const RoundedRectangleBorder(
          // Opsi: Tambah sudut melengkung di bawah AppBar
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8DD8FF), // biru muda (warna atas)
              Color(0xFF5409DA), // ungu gelap (warna bawah)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<SimpananAnggotaSummary>>(
          future: _simpananSummaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada data simpanan anggota.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final simpananSummaryList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(
                top: 8.0,
              ), // Beri jarak dari AppBar
              itemCount: simpananSummaryList.length,
              itemBuilder: (context, index) {
                final summary = simpananSummaryList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  color: Colors.white.withOpacity(0.9),
                  elevation: 4,
                  child: ListTile(
                    title: Text(
                      summary.namaAnggota,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Total Simpanan: Rp ${_currencyFormatter.format(summary.totalSimpanan)}',
                    ),
                    isThreeLine: false,
                    // Tambahkan onTap jika ingin melihat detail atau aksi lain
                    // onTap: () {
                    //   // Aksi saat item simpanan diklik
                    // },
                  ),
                );
              },
            );
          },
        ),
      ),
      // Jika Anda ingin menambahkan FAB untuk menambah simpanan, tambahkan di sini
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Aksi untuk menambah simpanan baru (mungkin navigasi ke form atau dialog)
      //   },
      //   tooltip: 'Tambah Simpanan',
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
