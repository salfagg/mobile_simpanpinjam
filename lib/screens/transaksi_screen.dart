import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpan_pinjam/models/anggota_model.dart';
import 'package:simpan_pinjam/models/pinjaman_model.dart';
import 'package:simpan_pinjam/models/simpanan_model.dart';
import 'package:simpan_pinjam/models/transaksi_model.dart';
import 'package:simpan_pinjam/services/supabase_service.dart';
import 'package:simpan_pinjam/main.dart'; // Untuk akses instance supabase global

enum JenisTransaksiEnum {
  setoranSimpanan('Setoran Simpanan'),
  penarikanSimpanan('Penarikan Simpanan'),
  pengajuanPinjaman('Pengajuan Pinjaman'),
  angsuranPinjaman('Angsuran Pinjaman');

  const JenisTransaksiEnum(this.displayName);
  final String displayName;
}

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final SupabaseService _supabaseService = SupabaseService(supabase);
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');
  final NumberFormat _currencyFormatter = NumberFormat("#,##0", "id_ID");

  JenisTransaksiEnum? _selectedJenisTransaksi;
  List<Anggota> _anggotaList = [];
  Anggota? _selectedAnggota;
  double _saldoAnggota = 0.0;

  // Controllers untuk form
  final _jumlahController = TextEditingController();
  DateTime _selectedTanggal = DateTime.now();
  final _bungaController = TextEditingController();

  // State khusus untuk simpanan dan pinjaman
  String? _selectedJenisSimpanan;
  final List<String> _opsiJenisSimpanan = ['Pokok', 'Wajib', 'Sukarela'];
  List<Pinjaman> _pinjamanAktifAnggota = [];
  Pinjaman? _selectedPinjamanUntukAngsuran;

  // Filter riwayat transaksi
  DateTime _filterStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _filterEndDate = DateTime.now();
  late Future<List<Transaksi>> _transaksiFuture;
  bool _isLoadingAnggota = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadTransaksiHistory();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingAnggota = true);
    try {
      final anggota = await _supabaseService.getAnggotaList();
      if (mounted) {
        setState(() {
          _anggotaList = anggota;
          _isLoadingAnggota = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAnggota = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar anggota: $e')),
        );
      }
    }
  }

  void _loadTransaksiHistory() {
    setState(() {
      _transaksiFuture = _supabaseService.getTransaksiByDateRange(
        _filterStartDate,
        _filterEndDate,
      );
    });
  }

  Future<void> _pickFilterDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _filterStartDate : _filterEndDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _filterStartDate = picked;
        } else {
          _filterEndDate = picked;
        }
        _loadTransaksiHistory();
      });
    }
  }

  Future<void> _pickFormDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Transaksi tidak boleh di masa depan
    );
    if (picked != null && picked != _selectedTanggal) {
      setState(() {
        _selectedTanggal = picked;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _jumlahController.clear();
    _bungaController.clear();
    setState(() {
      _selectedTanggal = DateTime.now();
      _selectedAnggota = null;
      _selectedJenisSimpanan = null;
      _pinjamanAktifAnggota = [];
      _selectedPinjamanUntukAngsuran = null;
      _saldoAnggota = 0.0;
    });
  }

  Future<void> _onAnggotaChanged(Anggota? anggota) async {
    setState(() {
      _selectedAnggota = anggota;
      _pinjamanAktifAnggota = [];
      _selectedPinjamanUntukAngsuran = null;
      _saldoAnggota = 0.0;
    });
    if (anggota != null && anggota.id != null) {
      try {
        final saldo = await _supabaseService.getSaldoSimpananAnggota(
          anggota.id!,
        );
        if (_selectedJenisTransaksi == JenisTransaksiEnum.angsuranPinjaman) {
          final pinjaman = await _supabaseService.getPinjamanAktifAnggota(
            anggota.id!,
          );
          if (mounted) {
            // Tambahkan mounted check di sini
            setState(() => _pinjamanAktifAnggota = pinjaman);
          }
        }
        if (mounted) {
          setState(() => _saldoAnggota = saldo);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat data anggota: $e')),
          );
        }
      }
    }
  }

  Future<void> _submitTransaksi() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJenisTransaksi == null || _selectedAnggota == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis transaksi dan anggota harus dipilih'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    String detailJenisTransaksi = _selectedJenisTransaksi!.displayName;

    try {
      final jumlah = double.parse(_jumlahController.text);
      if (_selectedJenisTransaksi == JenisTransaksiEnum.setoranSimpanan) {
        if (_selectedJenisSimpanan == null) {
          throw Exception('Jenis simpanan harus dipilih');
        }
        final simpanan = Simpanan(
          id_anggota: _selectedAnggota!.id!,
          tanggal_simpan:
              _selectedTanggal, // Model Simpanan harus punya field tanggal_simpan
          jumlah: jumlah, // Model Simpanan harus punya field jumlah
          jenis:
              _selectedJenisSimpanan!, // Model Simpanan harus punya field jenis
        );
        await _supabaseService.addSimpanan(
          simpanan,
        ); // Tidak lagi mengambil referensiId
        detailJenisTransaksi = "Setoran Simpanan - $_selectedJenisSimpanan";
      } else if (_selectedJenisTransaksi ==
          JenisTransaksiEnum.penarikanSimpanan) {
        if (jumlah > _saldoAnggota) {
          throw Exception(
            'Saldo tidak mencukupi. Saldo saat ini: Rp ${_currencyFormatter.format(_saldoAnggota)}',
          );
        }
        final simpanan = Simpanan(
          id_anggota: _selectedAnggota!.id!,
          tanggal_simpan:
              _selectedTanggal, // Model Simpanan harus punya field tanggal_simpan
          jumlah: -jumlah, // Model Simpanan harus punya field jumlah
          jenis: 'Penarikan', // Model Simpanan harus punya field jenis
        );
        await _supabaseService.addSimpanan(
          simpanan,
        ); // Tidak lagi mengambil referensiId
      } else if (_selectedJenisTransaksi ==
          JenisTransaksiEnum.pengajuanPinjaman) {
        final pinjaman = Pinjaman(
          id_anggota: _selectedAnggota!.id!,
          tanggal_pinjaman:
              _selectedTanggal, // Model Pinjaman harus punya field tanggal_pinjaman
          jumlah: jumlah, // Model Pinjaman harus punya field jumlah
          bunga:
              _bungaController.text.isNotEmpty
                  ? double.parse(_bungaController.text)
                  : 0.0,
          status_pinjaman: 'Aktif', // Model Pinjaman harus punya field status
        );
        await _supabaseService.addPinjaman(
          pinjaman,
        ); // Tidak lagi mengambil referensiId
      } else if (_selectedJenisTransaksi ==
          JenisTransaksiEnum.angsuranPinjaman) {
        if (_selectedPinjamanUntukAngsuran == null) {
          throw Exception('Pinjaman yang akan diangsur harus dipilih');
        }
        final pinjaman = _selectedPinjamanUntukAngsuran!;
        final sisaPinjaman =
            pinjaman.jumlah -
            jumlah; // Use 'jumlah' consistent with PinjamanModel
        // Menggunakan field 'jumlah' dan 'status' dari model Pinjaman yang sudah diperbarui
        pinjaman.jumlah = sisaPinjaman > 0 ? sisaPinjaman : 0;
        pinjaman.status_pinjaman = sisaPinjaman <= 0 ? 'Lunas' : 'Aktif';
        await _supabaseService.updatePinjaman(pinjaman);
        // referensiId tidak lagi digunakan untuk transaksi
        final updatedPinjaman = await _supabaseService.getPinjamanAktifAnggota(
          _selectedAnggota!.id!,
        );
        setState(() => _pinjamanAktifAnggota = updatedPinjaman);
      }

      final transaksi = Transaksi(
        id_anggota: _selectedAnggota!.id!,
        tanggal_transaksi: _selectedTanggal,
        jenis_transaksi: // Menggunakan field yang sudah diperbarui di model
            detailJenisTransaksi,
        jumlah: jumlah,
        // referensi_id dan keterangan tidak ada lagi di tabel transaksi
      );
      await _supabaseService.addTransaksi(transaksi);

      if (_selectedAnggota != null) {
        final updatedSaldo = await _supabaseService.getSaldoSimpananAnggota(
          _selectedAnggota!.id!,
        );
        setState(() => _saldoAnggota = updatedSaldo);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan')),
      );
      _resetForm();
      _loadTransaksiHistory();
    } catch (e) {
      print('Error saat submit transaksi: $e'); // Tambah logging
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteTransaksi(Transaksi transaksi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus transaksi ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      if (transaksi.id_transaksi == null) {
        throw Exception('ID transaksi tidak ditemukan');
      }
      await _supabaseService.deleteTransaksi(transaksi.id_transaksi!);

      // Logika untuk menghapus/membalikkan simpanan/pinjaman terkait
      // tidak lagi ada karena 'referensi_id' di tabel transaksi telah dihapus.
      // Jika fungsionalitas ini masih diperlukan, Anda perlu implementasi
      // cara lain untuk mengidentifikasi dan memodifikasi record terkait.
      // Misalnya, berdasarkan id_anggota, jumlah, dan tanggal yang berdekatan.

      // Muat ulang data yang relevan
      if (_selectedAnggota != null && _selectedAnggota!.id != null) {
        final updatedSaldo = await _supabaseService.getSaldoSimpananAnggota(
          _selectedAnggota!.id!,
        );
        if (mounted) setState(() => _saldoAnggota = updatedSaldo);

        // Jika anggota yang dipilih terkait dengan transaksi angsuran yang dihapus, perbarui daftar pinjaman aktifnya
        if (transaksi.id_anggota == _selectedAnggota!.id &&
            transaksi
                    .jenis_transaksi == // Menggunakan field yang sudah diperbarui di model
                JenisTransaksiEnum.angsuranPinjaman.displayName) {
          final pinjaman = await _supabaseService.getPinjamanAktifAnggota(
            _selectedAnggota!.id!,
          );
          if (mounted) setState(() => _pinjamanAktifAnggota = pinjaman);
        }
      }
      _loadTransaksiHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus/dibatalkan')),
      );
    } catch (e) {
      print('Error saat hapus transaksi: $e'); // Tambah logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(), // Tombol kembali tetap ada
        title: const Text('Manajemen Transaksi'),
        // Style AppBar biar nyambung sama gradasi
        backgroundColor: const Color(0xFF5409DA), // Warna dari gradasi bawah
        foregroundColor: Colors.white, // Warna teks dan ikon di AppBar
        elevation: 8, // Tambah sedikit bayangan
        shape: const RoundedRectangleBorder(
          // Opsi: Tambah sudut melengkung di bawah AppBar
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      // Tambahkan background gradasi ke body
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
        child: Column(
          // Wrap konten body yang sudah ada
          children: [
            _buildFormInputTransaksi(),
            if (_isSubmitting) // Show global progress indicator when submitting/deleting
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            // const Divider(height: 16, thickness: 1), // Divider mungkin kurang terlihat di gradasi, bisa dihapus
            _buildRiwayatTransaksi(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormInputTransaksi() {
    return Container(
      margin: const EdgeInsets.only(
        top: 16.0,
      ), // Tambahkan jarak di bagian atas container
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF5409DA), // Warna sama dengan AppBar
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16), // Bentuk sama dengan AppBar
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<JenisTransaksiEnum>(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                iconEnabledColor: Colors.white70,
                dropdownColor: const Color(0xFF5409DA), // Warna dropdown diubah
                decoration: InputDecoration(
                  labelText: 'Jenis Transaksi',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF8DD8FF).withOpacity(
                    0.3, // Diubah ke biru muda transparan
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Colors.white54,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                value: _selectedJenisTransaksi,
                items:
                    JenisTransaksiEnum.values.map((JenisTransaksiEnum jenis) {
                      return DropdownMenuItem<JenisTransaksiEnum>(
                        value: jenis,
                        child: Text(
                          jenis.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                          ), // Warna teks item di dalam list dropdown
                        ),
                      );
                    }).toList(), // <-- Ini sudah benar, ditambah koma
                // selectedItemBuilder tidak diperlukan untuk enum sederhana
                onChanged: (JenisTransaksiEnum? newValue) {
                  // <-- Ini properti onChanged
                  // Optional: Add a print statement here to see in console
                  // print('Jenis Transaksi Dropdown onChanged: $newValue'); // <-- Ini body onChanged
                  setState(() {
                    _selectedJenisTransaksi = newValue;
                    // Clear fields that might be specific to the previous type
                    _jumlahController.clear();
                    _bungaController.clear();
                    _selectedTanggal = DateTime.now(); // Reset date to current
                    _selectedAnggota = null; // Clear selected member
                    _selectedJenisSimpanan = null; // Clear simpanan type
                    _pinjamanAktifAnggota = []; // Clear pinjaman list
                    _selectedPinjamanUntukAngsuran =
                        null; // Clear selected pinjaman
                    _saldoAnggota = 0.0; // Reset saldo display
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Jenis transaksi harus dipilih' : null,
              ),
              const SizedBox(height: 16),
              // This is the crucial conditional block
              if (_selectedJenisTransaksi != null) ...[
                // Container( // Debug container bisa dihilangkan jika sudah tidak diperlukan
                //   width: double.infinity,
                //   padding: const EdgeInsets.all(8.0),
                //   color: Colors.yellow.withOpacity(0.3),
                //   child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Text( // Debug text bisa dihilangkan
                    //   'DEBUG: Form fields block IS VISIBLE!',
                    //   style: TextStyle(
                    //     color: Colors.purple,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // const SizedBox(height: 10), // Sesuaikan jarak jika debug text dihilangkan
                    if (_isLoadingAnggota)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      DropdownButtonFormField<Anggota>(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        iconEnabledColor: Colors.white70,
                        dropdownColor: const Color(
                          0xFF5409DA,
                        ), // Warna dropdown diubah
                        decoration: InputDecoration(
                          labelText: 'Anggota',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF8DD8FF).withOpacity(
                            0.3, // Diubah ke biru muda transparan
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white54,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        value: _selectedAnggota,
                        items:
                            _anggotaList.map((Anggota anggota) {
                              return DropdownMenuItem<Anggota>(
                                value: anggota,
                                child: Text(
                                  anggota.nama,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ); // Teks item anggota akan default hitam, jika dropdownColor gelap, perlu style
                            }).toList(),
                        selectedItemBuilder: (BuildContext context) {
                          // Untuk styling teks item yang terpilih di field
                          return _anggotaList.map<Widget>((Anggota item) {
                            return Text(
                              item.nama,
                              style: const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        }, // <-- Hapus '})' dan ',' di sini
                        onChanged:
                            _onAnggotaChanged, // <-- Ini properti onChanged
                        validator: // <-- Ini properti validator
                            (value) =>
                                value == null
                                    ? 'Anggota harus dipilih'
                                    : null, // <-- Ini body validator
                      ),
                      if (_selectedAnggota != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Saldo: Rp ${_currencyFormatter.format(_saldoAnggota)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              // Tambahkan shadow tipis untuk kedalaman
                              Shadow(
                                blurRadius: 1.0,
                                color: Colors.black38,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jumlahController,
                      style: const TextStyle(
                        color: Colors.white,
                      ), // Warna teks input
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF8DD8FF).withOpacity(
                          0.3, // Diubah ke biru muda transparan
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.white54,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah harus diisi';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Jumlah harus lebih besar dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tanggal: ${_dateFormatter.format(_selectedTanggal)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              shadows: [
                                // Tambahkan shadow tipis
                                Shadow(
                                  blurRadius: 1.0,
                                  color: Colors.black26,
                                  offset: Offset(0.5, 0.5),
                                ),
                              ],
                            ), // Ubah warna agar terbaca
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color:
                                Colors.white70, // Sesuaikan warna ikon kalender
                          ),
                          onPressed: () => _pickFormDate(context),
                        ),
                      ],
                    ),
                    if (_selectedJenisTransaksi ==
                        JenisTransaksiEnum.setoranSimpanan)
                      DropdownButtonFormField<String>(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        iconEnabledColor: Colors.white70,
                        dropdownColor: const Color(
                          0xFF5409DA,
                        ), // Warna dropdown diubah
                        decoration: InputDecoration(
                          labelText: 'Jenis Simpanan',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF8DD8FF).withOpacity(
                            0.3, // Diubah ke biru muda transparan
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white54,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        value: _selectedJenisSimpanan,
                        items:
                            _opsiJenisSimpanan.map((String jenis) {
                              return DropdownMenuItem<String>(
                                value: jenis,
                                child: Text(
                                  jenis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ); // Teks item akan default hitam, jika dropdownColor gelap, perlu style
                            }).toList(),
                        selectedItemBuilder: (BuildContext context) {
                          // Untuk styling teks item yang terpilih di field
                          return _opsiJenisSimpanan.map<Widget>((String item) {
                            return Text(
                              item,
                              style: const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        }, // <-- Hapus '})' dan ',' di sini
                        onChanged: (String? newValue) {
                          // <-- Ini properti onChanged
                          setState(
                            () => _selectedJenisSimpanan = newValue,
                          ); // <-- Ini body onChanged
                        },
                        validator: // <-- Ini properti validator
                            (value) =>
                                value == null
                                    ? 'Jenis simpanan harus dipilih'
                                    : null,
                      ),
                    if (_selectedJenisTransaksi ==
                        JenisTransaksiEnum.pengajuanPinjaman)
                      TextFormField(
                        controller: _bungaController,
                        style: const TextStyle(
                          color: Colors.white,
                        ), // Warna teks input
                        decoration: InputDecoration(
                          labelText: 'Bunga (%)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Opsional',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF8DD8FF).withOpacity(
                            0.3, // Diubah ke biru muda transparan
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white54,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Format bunga tidak valid';
                          }
                          return null;
                        },
                      ),
                    if (_selectedJenisTransaksi ==
                            JenisTransaksiEnum.angsuranPinjaman &&
                        _selectedAnggota != null)
                      DropdownButtonFormField<Pinjaman>(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        iconEnabledColor: Colors.white70,
                        dropdownColor: const Color(
                          0xFF5409DA,
                        ), // Warna dropdown diubah
                        decoration: InputDecoration(
                          labelText: 'Pilih Pinjaman untuk Diangsur',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF8DD8FF).withOpacity(
                            0.3, // Diubah ke biru muda transparan
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white54,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        value: _selectedPinjamanUntukAngsuran,
                        items:
                            _pinjamanAktifAnggota.map((Pinjaman pinjaman) {
                              return DropdownMenuItem<Pinjaman>(
                                value: pinjaman,
                                child: Text(
                                  'Pinjaman Rp ${_currencyFormatter.format(pinjaman.jumlah)} - Tgl: ${_dateFormatter.format(pinjaman.tanggal_pinjaman)}', // Menggunakan field model Pinjaman yang sudah diperbarui
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ), // Tambahkan style warna putih di sini
                                ),
                              );
                            }).toList(), // <-- Ini sudah benar
                        selectedItemBuilder: (BuildContext context) {
                          // <-- Ini properti selectedItemBuilder
                          return _pinjamanAktifAnggota.map<Widget>((
                            Pinjaman item,
                          ) {
                            return Text(
                              'Rp ${_currencyFormatter.format(item.jumlah)} - ${_dateFormatter.format(item.tanggal_pinjaman)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        }, // <-- Ini penutup selectedItemBuilder
                        onChanged: (Pinjaman? newValue) {
                          // <-- Ini properti onChanged
                          setState(
                            () => _selectedPinjamanUntukAngsuran = newValue,
                          );
                        },
                        validator:
                            (value) =>
                                value == null ? 'Pinjaman harus dipilih' : null,
                        isExpanded: true,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Simpan Transaksi'),
                          onPressed: _isSubmitting ? null : _submitTransaksi,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors
                                    .lightBlue
                                    .shade400, // Diubah ke biru muda
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          // Diubah menjadi ElevatedButton
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Form'),
                          onPressed: _resetForm,
                          style: ElevatedButton.styleFrom(
                            // Style disamakan
                            backgroundColor:
                                Colors
                                    .lightBlue
                                    .shade400, // Diubah ke biru muda
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ), // End of Row for buttons
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatTransaksi() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Gunakan Expanded agar teks tidak terpotong
                  child: Text(
                    'Riwayat Transaksi:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ), // Ubah warna dan tebalkan
                  ),
                ),
                // Filter tanggal bisa dibuat lebih kompak atau dipindahkan jika terlalu ramai
                // Untuk saat ini, kita biarkan dulu
              ],
            ),
          ),
          Padding(
            // Tambahkan padding untuk filter tanggal agar tidak terlalu mepet
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // Pindahkan ke kanan
              children: [
                Text(
                  'Filter: ${_dateFormatter.format(_filterStartDate)} s/d ${_dateFormatter.format(_filterEndDate)}', // Teks filter
                  style: const TextStyle(color: Colors.white70), // Ubah warna
                ),
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.white70,
                  ), // Ubah warna ikon
                  onPressed: () => _pickFilterDate(context, true),
                  tooltip: 'Tanggal Mulai',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.white70,
                  ), // Ubah warna ikon
                  onPressed: () => _pickFilterDate(context, false),
                  tooltip: 'Tanggal Akhir',
                ), // Ubah warna ikon
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Transaksi>>(
              future: _transaksiFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.white70,
                      ), // Tambahkan style warna
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada riwayat transaksi.',
                      style: TextStyle(color: Colors.white70),
                    ), // Tambahkan style warna
                  );
                }
                final transaksiList = snapshot.data!;
                return ListView.builder(
                  itemCount: transaksiList.length,
                  itemBuilder: (context, index) {
                    final transaksi = transaksiList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      color: Colors.white.withOpacity(
                        0.9,
                      ), // Tambahkan warna background Card
                      elevation:
                          4, // Atur elevation agar bayangan tetap terlihat
                      child: ListTile(
                        title: Text(
                          '${transaksi.jenis_transaksi} - ${transaksi.nama_anggota ?? transaksi.id_anggota}', // Menggunakan field yang sudah diperbarui
                        ),
                        subtitle: Text(
                          'Rp ${_currencyFormatter.format(transaksi.jumlah)}\n${_dateFormatter.format(transaksi.tanggal_transaksi)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon keterangan dihapus
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  _isSubmitting
                                      ? null // Disable delete if another operation is in progress
                                      : () => _deleteTransaksi(transaksi),
                            ),
                          ],
                        ),
                        // onTap untuk keterangan dihapus
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _bungaController.dispose();
    super.dispose();
  }
}
