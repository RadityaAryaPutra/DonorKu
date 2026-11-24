import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/admin/admin_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/donor/donor_shell.dart';
import 'features/home/home_placeholder.dart';
import 'features/requester/requester_shell.dart';

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

    switch (auth.user!.role) {
      case 'pendonor':
        return const DonorShell();
      case 'pemohon':
        return const RequesterShell();
      case 'admin':
        return const AdminScreen();
      default:
        return const HomePlaceholder();
    }
  }
}
