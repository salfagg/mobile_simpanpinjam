import 'package:flutter/material.dart';
import '../models/anggota_model.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnggotaScreen extends StatefulWidget {
  const AnggotaScreen({super.key});

  @override
  State<AnggotaScreen> createState() => _AnggotaScreenState();
}

class _AnggotaScreenState extends State<AnggotaScreen> {
  late SupabaseService supabaseService;
  List<Anggota> anggotaList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    supabaseService = SupabaseService(Supabase.instance.client);
    fetchAnggota();
  }

  Future<void> fetchAnggota() async {
    setState(() => loading = true);
    try {
      final list = await supabaseService.getAnggotaList();
      if (mounted) {
        setState(() {
          anggotaList = list;
        });
      }
    } catch (e, stackTrace) {
      print('Error fetching anggota: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data anggota: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showFormDialog({Anggota? anggota}) {
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: anggota?.nama ?? '');
    final alamatCtrl = TextEditingController(text: anggota?.alamat ?? '');
    final teleponCtrl = TextEditingController(text: anggota?.telepon ?? '');
    final emailCtrl = TextEditingController(text: anggota?.email ?? '');
    DateTime? tanggalMasuk = anggota?.tanggalMasuk;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(anggota == null ? 'Tambah Anggota' : 'Edit Anggota'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: namaCtrl,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Nama harus diisi'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: alamatCtrl,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: teleponCtrl,
                        decoration: const InputDecoration(labelText: 'Telepon'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email harus diisi';
                          }
                          final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!regex.hasMatch(value)) {
                            return 'Format email salah';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Tanggal Masuk: '),
                          Text(
                            tanggalMasuk != null
                                ? '${tanggalMasuk!.day}/${tanggalMasuk!.month}/${tanggalMasuk!.year}'
                                : '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tanggalMasuk ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  tanggalMasuk = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFF5409DA),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final anggotaToSave = Anggota(
                        id: anggota?.id,
                        nama: namaCtrl.text.trim(),
                        alamat: alamatCtrl.text.trim(),
                        telepon: teleponCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        tanggalMasuk: tanggalMasuk,
                      );
                      try {
                        if (anggota == null) {
                          await supabaseService.addAnggota(anggotaToSave);
                        } else {
                          if (anggotaToSave.id == null) {
                            throw Exception(
                              "ID Anggota tidak ditemukan untuk update.",
                            );
                          }
                          await supabaseService.updateAnggota(anggotaToSave);
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          fetchAnggota();
                        }
                      } catch (e, stackTrace) {
                        print('Error saving anggota: $e');
                        print(stackTrace);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan data: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus anggota ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await supabaseService.deleteAnggota(id);
        if (mounted) {
          fetchAnggota();
        }
      } catch (e, stackTrace) {
        print('Error deleting anggota: $e');
        print(stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus data: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Data Anggota'),
        backgroundColor: const Color(0xFF5409DA),
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        foregroundColor: Colors.white, // White color for the AppBar text
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchAnggota),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFormDialog(),
        backgroundColor: const Color(0xFF6222A7),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ), // Ensuring the icon color is white
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8DD8FF), Color(0xFF5409DA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:
            loading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : anggotaList.isEmpty
                ? const Center(
                  child: Text(
                    'Belum ada data anggota',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: anggotaList.length,
                  itemBuilder: (context, index) {
                    final anggota = anggotaList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      color: Colors.white.withOpacity(0.95),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        title: Text(
                          anggota.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF5409DA),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Email: ${anggota.email}\nTelepon: ${anggota.telepon}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF6222A7),
                              ),
                              tooltip: 'Edit Anggota',
                              onPressed: () => showFormDialog(anggota: anggota),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Hapus Anggota',
                              onPressed: () => confirmDelete(anggota.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
