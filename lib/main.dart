import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import untuk initializeDateFormatting
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard.dart';
import 'screens/anggota_screen.dart';
import 'screens/simpanan_screen.dart';
import 'screens/pinjaman_screen.dart';
import 'screens/transaksi_screen.dart';

const supabaseUrl = 'https://ozcxzwmsnbntxobvorcm.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96Y3h6d21zbmJudHhvYnZvcmNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxMzk3NjgsImV4cCI6MjA2MjcxNTc2OH0.kM8IIRCwh8BdSypMVezgoI1_u-Jaym6vRwqpaPxA2Ag';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi data lokal untuk pemformatan tanggal/waktu.
  // 'id_ID' untuk Bahasa Indonesia. Ganti jika perlu, atau null untuk lokal sistem.
  await initializeDateFormatting('id_ID', null);
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard', // Rute tujuan setelah login/register berhasil
      builder: (context, state) => const Dashboard(),
    ),
    GoRoute(
      path: '/edit_password', // Rute untuk lupa password dari login_screen
      builder:
          (context, state) => const Scaffold(
            body: Center(child: Text('Halaman Lupa Password')),
          ), // Ganti dengan screen sebenarnya nanti
    ),
    GoRoute(
      path: '/anggota',
      builder: (context, state) => const AnggotaScreen(),
    ),
    GoRoute(
      path: '/simpanan',
      builder: (context, state) => const SimpananScreen(),
    ),
    GoRoute(
      path: '/pinjaman',
      builder: (context, state) => const PinjamanScreen(),
    ),
    GoRoute(
      path: '/transaksi',
      builder: (context, state) => const TransaksiScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aplikasi Simpan Pinjam',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      routerConfig: _router,
      debugShowCheckedModeBanner: false, // Opsional: menghilangkan banner debug
    );
  }
}

// Instance Supabase client global
final supabase = Supabase.instance.client;
