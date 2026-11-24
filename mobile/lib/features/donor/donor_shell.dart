import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'donor_home_screen.dart';
import 'donor_profile_screen.dart';
import 'donor_provider.dart';

class DonorShell extends StatefulWidget {
  const DonorShell({super.key});

  @override
  State<DonorShell> createState() => _DonorShellState();
}

class _DonorShellState extends State<DonorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DonorProvider()..load(),
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              DonorHomeScreen(onOpenProfile: () => setState(() => _index = 1)),
              const DonorProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
