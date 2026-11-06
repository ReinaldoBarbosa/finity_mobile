import 'package:flutter/material.dart';

class FinityBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FinityBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color primaryColor = Color(0xFF4930C8);
  static const Color inactiveColor = Color(0xFF89869B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFEDEBF5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _buildItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Início',
              ),
              _buildItem(
                index: 1,
                icon: Icons.swap_horiz_rounded,
                label: 'Movimentações',
              ),
              _buildAddButton(),
              _buildItem(
                index: 3,
                icon: Icons.bar_chart_rounded,
                label: 'Relatórios',
              ),
              _buildItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primaryColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Expanded(
      child: Center(
        child: SizedBox(
          width: 46,
          height: 46,
          child: FloatingActionButton(
            heroTag: 'finity_add_transaction',
            onPressed: () => onTap(2),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.add_rounded,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
