import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:simpan_pinjam/main.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double? _totalSimpanan;
  double? _totalPinjaman;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    print("[DEBUG] _fetchDashboardData: Mulai dijalankan.");
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print(
      "[DEBUG] _fetchDashboardData: State diatur ke isLoading=true, errorMessage=null.",
    );

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        print("[DEBUG] _fetchDashboardData: User tidak login.");
        setState(() {
          _errorMessage = 'Pengguna tidak login. Silakan login kembali.';
          _totalSimpanan = 0.0;
          _totalPinjaman = 0.0;
          _isLoading = false;
        });
      }
      print("[DEBUG] _fetchDashboardData: Selesai (user tidak login).");
      return;
    }
    try {
      print(
        "[DEBUG] _fetchDashboardData: Mencoba mengambil data untuk user ID: ${user.id}",
      );
      // Memanggil fungsi RPC baru untuk total keseluruhan simpanan
      final dynamic totalSimpananRes = await supabase.rpc(
        'get_grand_total_simpanan',
      );
      final double currentTotalSimpanan =
          (totalSimpananRes as num?)?.toDouble() ?? 0.0;

      print(
        "[DEBUG] _fetchDashboardData: Hasil get_grand_total_simpanan: $totalSimpananRes, diparsing jadi: $currentTotalSimpanan",
      );
      // Memanggil fungsi RPC baru untuk total keseluruhan pinjaman
      final dynamic totalPinjamanRes = await supabase.rpc(
        'get_grand_total_pinjaman',
      );
      final double currentTotalPinjaman =
          (totalPinjamanRes as num?)?.toDouble() ?? 0.0;

      print(
        "[DEBUG] _fetchDashboardData: Hasil get_grand_total_pinjaman: $totalPinjamanRes, diparsing jadi: $currentTotalPinjaman",
      );
      if (mounted) {
        setState(() {
          _totalSimpanan = currentTotalSimpanan;
          _totalPinjaman = currentTotalPinjaman;
          _isLoading = false;
        });
      }
    } on PostgrestException catch (error) {
      print(
        "[DEBUG] _fetchDashboardData: Terjadi PostgrestException: ${error.message}",
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data: ${error.message}';
          _totalSimpanan = 0.0;
          _totalPinjaman = 0.0;
          _isLoading = false;
        });
      }
    } catch (error) {
      print(
        "[DEBUG] _fetchDashboardData: Terjadi error umum: ${error.toString()}",
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${error.toString()}';
          _totalSimpanan = 0.0;
          _totalPinjaman = 0.0;
          _isLoading = false;
        });
      }
    }
    print("[DEBUG] _fetchDashboardData: Selesai.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8DD8FF), // biru muda
              Color(0xFF5409DA), // ungu gelap
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // APPBAR custom dengan gradasi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5409DA), Color(0xFF4E71FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dashboard Simpan Pinjam',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 1.3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await supabase.auth.signOut();
                        if (mounted) {
                          context.go('/login');
                        }
                      },
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20,
                    ),
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Penting untuk RefreshIndicator
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildUserInfoCard(),
                          const SizedBox(height: 30),
                          Text(
                            'Menu Utama',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              shadows: const [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            children: [
                              AnimatedMenuCard(
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'Simpanan',
                                onTap: () => context.push('/simpanan'),
                              ),
                              AnimatedMenuCard(
                                icon: Icons.monetization_on_outlined,
                                title: 'Pinjaman',
                                onTap: () => context.push('/pinjaman'),
                              ),
                              AnimatedMenuCard(
                                icon: Icons.receipt_long_outlined,
                                title: 'Transaksi',
                                onTap: () => context.push('/transaksi'),
                              ),
                              AnimatedMenuCard(
                                icon: Icons.people_alt_outlined,
                                title: 'Anggota',
                                onTap: () => context.push('/anggota'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ), // Adjusted padding
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFinancialInfoRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Total Simpanan:',
                      value: _totalSimpanan,
                      valueColor: Colors.green.shade700,
                    ),
                    const SizedBox(height: 16),
                    _buildFinancialInfoRow(
                      icon: Icons.request_quote_outlined,
                      label: 'Total Pinjaman:',
                      value: _totalPinjaman,
                      valueColor: Colors.orange.shade800,
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildFinancialInfoRow({
    required IconData icon,
    required String label,
    required double? value,
    Color valueColor = const Color(0xFF5409DA),
  }) {
    // Untuk format mata uang yang lebih baik, pertimbangkan menggunakan package 'intl'
    // import 'package:intl/intl.dart';
    // final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String formatCurrency(double? amount) {
      if (amount == null) return 'Rp 0';
      // Format sederhana, ganti dengan package intl untuk produksi
      return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }

    return Row(
      children: [
        Icon(icon, size: 26, color: Colors.grey.shade700),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          formatCurrency(value),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class AnimatedMenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color backgroundColor;

  const AnimatedMenuCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.backgroundColor = const Color(0xFF5409DA),
  }) : super(key: key);

  @override
  State<AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<AnimatedMenuCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          borderRadius: BorderRadius.circular(26),
          elevation: 8,
          color: widget.backgroundColor,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 52, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    letterSpacing: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
