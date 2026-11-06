import 'package:flutter/material.dart';

import './../../../core/services/contas_receber_api.dart';
import './../../../core/theme/app_theme.dart';
import 'new_receivable_screen.dart';
import 'account_receivable_details_screen.dart';

class AccountsReceivableScreen extends StatefulWidget {
  const AccountsReceivableScreen({super.key});

  @override
  State<AccountsReceivableScreen> createState() =>
      _AccountsReceivableScreenState();
}

class _AccountsReceivableScreenState
    extends State<AccountsReceivableScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'Todas';

  List<Map<String, dynamic>> _accounts = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARREGAMENTO DAS CONTAS
  // ============================================================

  double _numberValue(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(',', '.'),
        ) ??
        0.0;
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contas = await ContasReceberApi.listar();

      final contasAtivas = contas.where((conta) {
        return conta['cancelada'] != true;
      }).toList();

      if (!mounted) return;

      setState(() {
        _accounts = contasAtivas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Future<void> _openAccountDetails(
    Map<String, dynamic> account,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AccountReceivableDetailsScreen(
          account: account,
        ),
      ),
    );

    if (!mounted) return;

    // Atualiza os valores ao voltar dos detalhes.
    await _loadAccounts();
  }

  Future<void> _openNewAccountForm() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const NewReceivableScreen(),
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      await _loadAccounts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta a receber salva com sucesso!'),
        ),
      );
    }
  }

  // ============================================================
  // STATUS DAS CONTAS
  // ============================================================

  String _statusOf(Map<String, dynamic> account) {
    final situacao = (account['situacao'] ?? 'Pendente')
        .toString()
        .trim()
        .toLowerCase();

    if (situacao.contains('cancelad')) {
      return 'Cancelada';
    }

    if (situacao.contains('vencid')) {
      return 'Vencida';
    }

    if (situacao.contains('parcial')) {
      return 'Parcial';
    }

    if (situacao.contains('recebid')) {
      return 'Recebida';
    }

    final dataVencimento = DateTime.tryParse(
      (account['dataVencimento'] ?? '').toString(),
    );

    final saldoPendente = _numberValue(
      account['saldoPendente'],
    );

    final hoje = DateTime.now();

    final hojeSemHora = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    if (dataVencimento != null &&
        saldoPendente > 0 &&
        DateTime(
          dataVencimento.year,
          dataVencimento.month,
          dataVencimento.day,
        ).isBefore(hojeSemHora)) {
      return 'Vencida';
    }

    return 'Em aberto';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Recebida':
        return AppTheme.successColor;

      case 'Vencida':
        return AppTheme.errorColor;

      case 'Parcial':
        return AppTheme.infoColor;

      case 'Cancelada':
        return AppTheme.cancelledColor;

      default:
        return AppTheme.warningColor;
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'Recebida':
        return const Color(0xFFE7F7EF);

      case 'Vencida':
        return const Color(0xFFFFEEEE);

      case 'Parcial':
        return const Color(0xFFEAF5FC);

      case 'Cancelada':
        return const Color(0xFFF1F0F6);

      default:
        return const Color(0xFFFFF7E8);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Recebida':
        return Icons.check_circle_outline_rounded;

      case 'Vencida':
        return Icons.error_outline_rounded;

      case 'Parcial':
        return Icons.payments_outlined;

      case 'Cancelada':
        return Icons.cancel_outlined;

      default:
        return Icons.schedule_rounded;
    }
  }

  // ============================================================
  // PESQUISA E FILTROS
  // ============================================================

  List<Map<String, dynamic>> get _filteredAccounts {
    final search = _searchController.text.toLowerCase().trim();

    return _accounts.where((account) {
      final description = (account['descricao'] ?? '')
          .toString()
          .toLowerCase();

      final category = (
        account['nomeCategoria'] ??
        account['categoria'] ??
        'Categoria ${account['idCategoria'] ?? ''}'
      ).toString().toLowerCase();

      final status = _statusOf(account);

      final matchesSearch =
          description.contains(search) ||
          category.contains(search);

      final matchesFilter =
          _selectedFilter == 'Todas' ||
          status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ============================================================
  // RESUMOS FINANCEIROS
  // ============================================================

  double _totalByStatus(String status) {
    return _accounts
        .where((account) => _statusOf(account) == status)
        .fold<double>(
          0.0,
          (total, account) =>
              total + _numberValue(account['saldoPendente']),
        );
  }

  double _totalReceived() {
    return _accounts.fold<double>(
      0.0,
      (total, account) =>
          total + _numberValue(account['totalRecebido']),
    );
  }

  // ============================================================
  // FORMATAÇÃO
  // ============================================================

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');

    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      buffer.write(integerPart[i]);

      final remaining = integerPart.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},$decimalPart';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Não informada';

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // TELA PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      appBar: AppBar(
        title: const Text('Contas a Receber'),
        actions: [
          IconButton(
            tooltip: 'Atualizar contas',
            onPressed: _loadAccounts,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAccounts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acompanhe os valores que sua empresa tem a receber.',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                _buildSummary(),

                const SizedBox(height: 28),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lançamentos',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (!_isLoading && _errorMessage == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        child: Text(
                          '${_filteredAccounts.length}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                _buildSearchField(),

                const SizedBox(height: 14),

                _buildFilters(),

                const SizedBox(height: 20),

                _buildContent(),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewAccountForm,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nova conta',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO FINANCEIRO
  // ============================================================

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visão geral',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'A receber',
                value: _formatCurrency(
                  _totalByStatus('Em aberto') +
                      _totalByStatus('Parcial') +
                      _totalByStatus('Vencida'),
                ),
                icon: Icons.account_balance_wallet_outlined,
                color: AppTheme.primaryColor,
                background: const Color(0xFFF0EAFE),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildSummaryCard(
                title: 'Vencidas',
                value: _formatCurrency(
                  _totalByStatus('Vencida'),
                ),
                icon: Icons.warning_amber_rounded,
                color: AppTheme.errorColor,
                background: const Color(0xFFFFEEEE),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildSummaryCard(
          title: 'Recebidas',
          value: _formatCurrency(_totalReceived()),
          icon: Icons.check_circle_outline_rounded,
          color: AppTheme.successColor,
          background: const Color(0xFFE7F7EF),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color background,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAMPO DE PESQUISA
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        hintText: 'Buscar conta por descrição ou categoria...',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppTheme.secondaryTextColor,
        ),
      ),
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _buildFilters() {
    const filters = [
      'Todas',
      'Em aberto',
      'Vencida',
      'Parcial',
      'Recebida',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.cardColor,
              side: BorderSide(
                color: selected
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
              ),
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : AppTheme.textColor,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // CONTEÚDO DA LISTA
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppTheme.errorColor,
            ),

            const SizedBox(height: 12),

            const Text(
              'Não foi possível carregar as contas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _loadAccounts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return _buildAccountList();
  }

  Widget _buildAccountList() {
    final accounts = _filteredAccounts;

    if (accounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 36,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: AppTheme.secondaryTextColor,
            ),

            SizedBox(height: 12),

            Text(
              'Nenhuma conta encontrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 6),

            Text(
              'Tente mudar o filtro ou o termo da busca.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: accounts.map((account) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAccountCard(account),
        );
      }).toList(),
    );
  }

  // ============================================================
  // CARTÃO DA CONTA
  // ============================================================

  Widget _buildAccountCard(
    Map<String, dynamic> account,
  ) {
    final status = _statusOf(account);

    final descricao =
        (account['descricao'] ?? 'Sem descrição').toString();

    final categoria = (
      account['nomeCategoria'] ??
      account['categoria'] ??
      'Categoria ${account['idCategoria'] ?? ''}'
    ).toString();

    final valorPendente = _numberValue(
      account['saldoPendente'],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAccountDetails(account),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EAFE),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.primaryColor,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descricao,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          categoria,
                          style: const TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Flexible(
                    child: Text(
                      _formatCurrency(valorPendente),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(
                  height: 1,
                  color: AppTheme.borderColor,
                ),
              ),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.secondaryTextColor,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      'Vencimento: '
                      '${_formatDate(account['dataVencimento'])}',
                      style: const TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(status),
                          size: 13,
                          color: _statusColor(status),
                        ),

                        const SizedBox(width: 4),

                        Text(
                          status,
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver detalhes',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(width: 4),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}