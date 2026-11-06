import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../../features/movements/presentation/movements_screen.dart';
import '../../features/accounts_payable/presentation/accounts_payable_screen.dart';
import '../../features/accounts_receivable/presentation/accounts_receivable_screen.dart';
import '../../features/options/presentation/create_options_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAccountsPayable() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountsPayableScreen(),
      ),
    );
  }

  void _openAccountsReceivable() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountsReceivableScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            onOpenAccountsPayable: _openAccountsPayable,
            onOpenAccountsReceivable: _openAccountsReceivable,
          ),
          const MovementsScreen(),
          const CreateOptionsScreen(),
          const _PlaceholderScreen(
            title: 'Relatórios',
            icon: Icons.bar_chart_rounded,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: FinityBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: const Color(0xFF4930C8),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF211D3A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vamos construir esta tela em seguida.',
                style: TextStyle(
                  color: Color(0xFF777489),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}