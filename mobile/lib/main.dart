import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/donor/donor_shell.dart';
import 'features/home/home_placeholder.dart';

void main() {
  runApp(const DonorKuApp());
}

class DonorKuApp extends StatelessWidget {
  const DonorKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..restore(),
      child: MaterialApp(
        title: 'DonorKu',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) return const LoginScreen();

    // Pendonor punya layar sendiri. Pemohon dan admin menyusul.
    return auth.user!.role == 'pendonor'
        ? const DonorShell()
        : const HomePlaceholder();
  }
}
