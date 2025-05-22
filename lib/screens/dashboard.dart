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
  String? _userName;
  String? _userEmail;
  String? _joinDate;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _userName = 'Pengguna tidak login';
          _userEmail = '';
          _joinDate = '';
        });
      }
      return;
    }

    try {
      final data =
          await supabase
              .from('anggota')
              .select('nama, email, tanggal_masuk')
              .eq('id_anggota', user.id)
              .single();

      if (mounted) {
        setState(() {
          _userName = data['nama'] as String?;
          _userEmail = data['email'] as String?;
          final rawJoinDate = data['tanggal_masuk'];

          if (rawJoinDate is String) {
            try {
              final dateTime = DateTime.parse(rawJoinDate);
              _joinDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
            } catch (e) {
              _joinDate = rawJoinDate;
            }
          } else {
            _joinDate = rawJoinDate?.toString();
          }
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _userName = 'Gagal memuat data';
          _userEmail = error.message;
          _joinDate = '';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _userName = 'Terjadi kesalahan';
          _userEmail = error.toString();
          _joinDate = '';
        });
      }
    }
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20,
                  ),
                  child: SingleChildScrollView(
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child:
            (_userName == null && _userEmail == null)
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName == 'Pengguna tidak login' ||
                              _userName == 'Gagal memuat data' ||
                              _userName == 'Terjadi kesalahan'
                          ? 'Info Pengguna'
                          : 'Selamat datang,',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (_userName != null &&
                        !_userName!.contains('tidak login') &&
                        !_userName!.contains('Gagal') &&
                        !_userName!.contains('Terjadi'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Text(
                          _userName!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5409DA),
                          ),
                        ),
                      ),
                    if (_userEmail != null && _userEmail!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _userEmail!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    if (_joinDate != null && _joinDate!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Bergabung: $_joinDate',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
      ),
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
