import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

// Ajuste os caminhos abaixo se suas telas estiverem em outras pastas.
import '../../movements/presentation/new_movement_screen.dart';
import '../../accounts_payable/presentation/new_payable_screen.dart';
import '../../accounts_receivable/presentation/new_receivable_screen.dart';

class CreateOptionsScreen extends StatelessWidget {
  const CreateOptionsScreen({super.key});

  Future<void> _abrirContaPagar(BuildContext context) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewPayableScreen(),
      ),
    );

    if (!context.mounted) return;

    if (resultado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta a pagar cadastrada com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _abrirContaReceber(BuildContext context) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewReceivableScreen(),
      ),
    );

    if (!context.mounted) return;

    if (resultado == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta a receber cadastrada com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _abrirMovimentacao(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewMovementScreen(),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppTheme.borderColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.secondaryTextColor,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Criar novo'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'O que você deseja criar?',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha uma opção para continuar.',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            _buildOption(
              context: context,
              title: 'Conta a pagar',
              subtitle: 'Cadastre despesas e organize seus vencimentos.',
              icon: Icons.arrow_upward_rounded,
              color: AppTheme.errorColor,
              onTap: () => _abrirContaPagar(context),
            ),

            const SizedBox(height: 14),

            _buildOption(
              context: context,
              title: 'Conta a receber',
              subtitle: 'Cadastre receitas e acompanhe os recebimentos.',
              icon: Icons.arrow_downward_rounded,
              color: AppTheme.successColor,
              onTap: () => _abrirContaReceber(context),
            ),

            const SizedBox(height: 14),

            _buildOption(
              context: context,
              title: 'Movimentação',
              subtitle: 'Registre entradas e saídas financeiras.',
              icon: Icons.swap_horiz_rounded,
              color: AppTheme.primaryColor,
              onTap: () => _abrirMovimentacao(context),
            ),
          ],
        ),
      ),
    );
  }
}
