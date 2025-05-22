import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pinjaman_anggota_summary_model.dart';
import '../services/supabase_service.dart';
import 'package:simpan_pinjam/main.dart';

class PinjamanScreen extends StatefulWidget {
  const PinjamanScreen({super.key});
  @override
  State<PinjamanScreen> createState() => _PinjamanScreenState();
}

// Pastikan Anda sudah membuat file pinjaman_anggota_summary_model.dart

class _PinjamanScreenState extends State<PinjamanScreen> {
  final SupabaseService _supabaseService = SupabaseService(supabase);
  late Future<List<PinjamanAnggotaSummary>> _pinjamanSummaryFuture;
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy');

  // Form controllers and variables for dialog sudah dihapus
  // _formKey, _selectedAnggotaId, _jumlahController, _selectedTanggalPinjam, _keteranganController

  @override
  void initState() {
    super.initState();
    _loadPinjamanSummary();
  }

  void _loadPinjamanSummary() {
    // Metode diganti untuk mengambil data ringkasan
    setState(() {
      _pinjamanSummaryFuture =
          _supabaseService.getPinjamanAktifSummaryPerAnggota();
    });
  }

  // Future<void> _loadAnggotaList() async { ... } // Dihapus
  // Future<void> _pickTanggalPinjam(BuildContext context) async { ... } // Dihapus
  // void _showAddPinjamanDialog() { ... } // Dihapus

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white), // Warna tombol kembali
        title: const Text(
          'Ringkasan Pinjaman Aktif',
          style: TextStyle(color: Colors.white),
        ), // Judul dan warna teks
        backgroundColor: const Color(0xFF5409DA), // Warna background AppBar
        elevation: 6, // Elevation AppBar
        shape: const RoundedRectangleBorder(
          // Bentuk AppBar
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ), // Ikon refresh dan warnanya
            onPressed: _loadPinjamanSummary, // Aksi refresh
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: Container(
        // Tambahkan Container untuk background gradasi
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8DD8FF), Color(0xFF5409DA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<PinjamanAnggotaSummary>>(
          future: _pinjamanSummaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ); // Warna loading indicator
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ), // Style teks error
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada data sisa pinjaman aktif.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ), // Style teks kosong
                ),
              );
            }

            final pinjamanSummaryList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ), // Padding untuk ListView
              itemCount: pinjamanSummaryList.length,
              itemBuilder: (context, index) {
                final summary = pinjamanSummaryList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ), // Margin Card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ), // Bentuk Card
                  elevation: 4, // Elevation Card
                  color: Colors.white.withOpacity(
                    0.95,
                  ), // Warna background Card
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ), // Padding ListTile
                    title: Text(
                      summary.namaAnggota,
                      style: const TextStyle(
                        // Style untuk title
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF5409DA),
                      ),
                    ),
                    subtitle: Padding(
                      // Padding untuk subtitle
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Total Sisa Pinjaman Aktif: Rp ${NumberFormat("#,##0", "id_ID").format(summary.totalSisaPinjamanAktif)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ), // Style untuk subtitle
                      ),
                    ),
                    isThreeLine: false, // Sesuaikan jika perlu
                    // onTap: () { // Contoh jika ingin ada aksi onTap
                    //   // Navigasi atau tampilkan detail
                    // },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _jumlahController.dispose(); // Dihapus
    // _keteranganController.dispose(); // Dihapus
    super.dispose();
  }
}
