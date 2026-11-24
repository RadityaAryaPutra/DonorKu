import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'requester_account_screen.dart';
import 'requester_home_screen.dart';
import 'requester_provider.dart';

class RequesterShell extends StatefulWidget {
  const RequesterShell({super.key});

  @override
  State<RequesterShell> createState() => _RequesterShellState();
}

class _RequesterShellState extends State<RequesterShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RequesterProvider()..load(),
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: const [RequesterHomeScreen(), RequesterAccountScreen()],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.water_drop_outlined),
              selectedIcon: Icon(Icons.water_drop),
              label: 'Permintaan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
