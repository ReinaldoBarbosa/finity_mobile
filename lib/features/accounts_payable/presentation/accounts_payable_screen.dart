import 'package:flutter/material.dart';

import './../../../core/services/contas_pagar_api.dart';
import './../../../core/theme/app_theme.dart';
import 'account_payable_details_screen.dart';
import 'new_payable_screen.dart';

class AccountsPayableScreen extends StatefulWidget {
  const AccountsPayableScreen({super.key});

  @override
  State<AccountsPayableScreen> createState() =>
      _AccountsPayableScreenState();
}

class _AccountsPayableScreenState extends State<AccountsPayableScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'Todas';

  List<Map<String, dynamic>> _accounts = [];

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  // ============================================================
  // CARREGAMENTO DAS CONTAS
  // ============================================================

  double _numberValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return 0.0;
    }

    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dados = await ContasPagarApi.listar();

      final accounts = dados.map<Map<String, dynamic>>((conta) {
        final dataOriginal = conta['dataVencimento']?.toString();

        final dataVencimento = DateTime.tryParse(
          dataOriginal ?? '',
        );

        final hoje = DateTime.now();

        final hojeSemHora = DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        );

        final vencimentoSemHora = dataVencimento == null
            ? null
            : DateTime(
                dataVencimento.year,
                dataVencimento.month,
                dataVencimento.day,
              );

        final situacao = conta['situacao']?.toString() ?? 'Pendente';

        final cancelada = conta['cancelada'] == true;

        final valorOriginal = _numberValue(
          conta['valorOriginal'],
        );

        final totalPago = _numberValue(
          conta['totalPago'],
        );

        final saldoPendente = conta['saldoPendente'] != null
            ? _numberValue(conta['saldoPendente'])
            : (valorOriginal - totalPago)
                .clamp(0.0, double.infinity)
                .toDouble();

        String status;

        if (cancelada || situacao == 'Cancelada') {
          status = 'Cancelada';
        } else if (situacao == 'Paga') {
          status = 'Paga';
        } else if (situacao == 'Parcial') {
          status = 'Parcial';
        } else if (vencimentoSemHora != null &&
            vencimentoSemHora.isBefore(hojeSemHora)) {
          status = 'Vencida';
        } else {
          status = 'Em aberto';
        }

        final descricao = conta['descricao']?.toString() ?? '';

        final idCategoria = conta['idCategoria'];

        return <String, dynamic>{
          // Campos utilizados na listagem.
          'id': conta['id'],
          'description': descricao,
          'category': 'Categoria $idCategoria',
          'dueDate': dataVencimento == null
              ? 'Não informada'
              : _formatDate(dataVencimento),
          'amount': valorOriginal,
          'saldoPendente': saldoPendente,
          'status': status,

          // Campos originais utilizados nos detalhes e pagamentos.
          'idEmpresa': conta['idEmpresa'],
          'idCategoria': conta['idCategoria'],
          'idCentroCusto': conta['idCentroCusto'],
          'descricao': descricao,
          'valorOriginal': valorOriginal,
          'dataEmissao': conta['dataEmissao'],
          'dataVencimento': conta['dataVencimento'],
          'dataVencimentoApi': conta['dataVencimento'],
          'totalPago': totalPago,
          'cancelada': cancelada,
          'situacao': situacao,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Future<void> _openNewAccountForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewPayableScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadAccounts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta a pagar salva com sucesso!'),
        ),
      );
    }
  }

  Future<void> _openAccountDetails(
    Map<String, dynamic> account,
  ) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountPayableDetailsScreen(
          account: Map<String, dynamic>.from(account),
        ),
      ),
    );

    if (!mounted) return;

    // Atualiza a lista ao voltar dos detalhes,
    // inclusive após registrar um pagamento.
    await _loadAccounts();
  }

  // ============================================================
  // PESQUISA E FILTROS
  // ============================================================

  List<Map<String, dynamic>> get _filteredAccounts {
    final search = _searchController.text.toLowerCase().trim();

    return _accounts.where((account) {
      final description = account['description']
          .toString()
          .toLowerCase();

      final category = account['category']
          .toString()
          .toLowerCase();

      final status = account['status'].toString();

      final matchesSearch =
          description.contains(search) ||
          category.contains(search);

      final matchesFilter = switch (_selectedFilter) {
        'Em aberto' =>
          status == 'Em aberto' || status == 'Parcial',
        'Vencidas' => status == 'Vencida',
        'Pagas' => status == 'Paga',
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  double _totalForStatus(String status) {
    return _accounts
        .where((account) {
          if (status == 'Em aberto') {
            return account['status'] == 'Em aberto' ||
                account['status'] == 'Parcial';
          }

          return account['status'] == status;
        })
        .fold<double>(0, (total, account) {
          if (status == 'Paga') {
            return total + _numberValue(account['amount']);
          }

          return total + _numberValue(account['saldoPendente']);
        });
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // TELA PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      appBar: AppBar(
        title: const Text('Contas a Pagar'),
        actions: [
          IconButton(
            onPressed: _loadAccounts,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar contas',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAccounts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acompanhe seus compromissos financeiros '
                  'e mantenha suas contas em dia.',
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
                title: 'Em aberto',
                value: _formatCurrency(
                  _totalForStatus('Em aberto'),
                ),
                icon: Icons.schedule_rounded,
                color: AppTheme.primaryColor,
                background: const Color(0xFFF0EAFE),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildSummaryCard(
                title: 'Vencidas',
                value: _formatCurrency(
                  _totalForStatus('Vencida'),
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
          title: 'Pagas',
          value: _formatCurrency(
            _totalForStatus('Paga'),
          ),
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
      'Vencidas',
      'Pagas',
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
    final status = account['status'] as String;

    final Color statusColor;
    final Color statusBackground;
    final IconData statusIcon;

    switch (status) {
      case 'Vencida':
        statusColor = AppTheme.errorColor;
        statusBackground = const Color(0xFFFFEEEE);
        statusIcon = Icons.error_outline_rounded;
        break;

      case 'Paga':
        statusColor = AppTheme.successColor;
        statusBackground = const Color(0xFFE7F7EF);
        statusIcon = Icons.check_circle_outline_rounded;
        break;

      case 'Parcial':
        statusColor = AppTheme.infoColor;
        statusBackground = const Color(0xFFEAF5FC);
        statusIcon = Icons.payments_outlined;
        break;

      case 'Cancelada':
        statusColor = AppTheme.cancelledColor;
        statusBackground = const Color(0xFFF1F0F6);
        statusIcon = Icons.cancel_outlined;
        break;

      default:
        statusColor = AppTheme.warningColor;
        statusBackground = const Color(0xFFFFF7E8);
        statusIcon = Icons.schedule_rounded;
    }

    final saldoPendente = _numberValue(
      account['saldoPendente'],
    );

    final amount = _numberValue(
      account['amount'],
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
                          account['description'] as String,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          account['category'] as String,
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
                      _formatCurrency(amount),
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
                      'Vencimento: ${account['dueDate']}',
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
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 13,
                          color: statusColor,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (saldoPendente > 0 && status != 'Cancelada') ...[
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Pendente: ${_formatCurrency(saldoPendente)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

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