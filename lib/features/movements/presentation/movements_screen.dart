import 'package:flutter/material.dart';

import './../../../core/services/movimentacao_api.dart';
import '../../../core/theme/app_theme.dart';
import 'movimentacao_detalhes_screen.dart';
import 'new_movement_screen.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  int _selectedFilter = 0;

  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _movements = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarMovimentacoes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARREGAMENTO DA API
  // ============================================================

  Future<void> _carregarMovimentacoes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dados = await MovimentacaoApi.listar();

      if (!mounted) return;

      final movimentacoesAtivas = dados.where((movement) {
        final cancelada =
            movement['Cancelada'] ??
            movement['cancelada'] ??
            false;

        return cancelada != true;
      }).toList();

      movimentacoesAtivas.sort((a, b) {
        final dataA = _parseDate(
          a['DataMovimentacao'] ??
              a['dataMovimentacao'],
        );

        final dataB = _parseDate(
          b['DataMovimentacao'] ??
              b['dataMovimentacao'],
        );

        final comparacao = dataB.compareTo(dataA);

        if (comparacao != 0) {
          return comparacao;
        }

        final idA = _toInt(a['Id'] ?? a['id']);
        final idB = _toInt(b['Id'] ?? b['id']);

        return idB.compareTo(idA);
      });

      setState(() {
        _movements = movimentacoesAtivas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _mensagemErro(e);
      });
    }
  }

  String _mensagemErro(Object erro) {
    final mensagem = erro.toString();

    if (mensagem.startsWith('Exception: ')) {
      return mensagem.substring('Exception: '.length);
    }

    return 'Não foi possível carregar as movimentações. '
        'Verifique sua conexão e tente novamente.';
  }

  // ============================================================
  // ABRIR DETALHES DA MOVIMENTAÇÃO
  // ============================================================

  Future<void> _abrirDetalhes(
    Map<String, dynamic> movement,
  ) async {
    final id = _toInt(
      movement['Id'] ?? movement['id'],
    );

    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar esta movimentação.',
          ),
        ),
      );
      return;
    }

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MovimentacaoDetalhesScreen(
          idMovimentacao: id,
        ),
      ),
    );

    if (!mounted) return;

    // Se houve estorno, atualiza a lista ao voltar.
    if (resultado == true) {
      await _carregarMovimentacoes();
    }
  }

  // ============================================================
  // ABRIR TELA DE NOVA MOVIMENTAÇÃO
  // ============================================================

  Future<void> _abrirNovaMovimentacao() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const NewMovementScreen(),
      ),
    );

    if (!mounted) return;

    // Atualiza a lista caso a movimentação tenha sido salva.
    if (resultado == true) {
      await _carregarMovimentacoes();
    }
}
  // ============================================================
  // CONVERSÃO DOS DADOS
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ?? '',
        ) ??
        DateTime(2000);
  }

  String _getType(Map<String, dynamic> movement) {
    return (movement['Tipo'] ?? movement['tipo'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
  }

  bool _isIncome(Map<String, dynamic> movement) {
    return _getType(movement) == 'RECEITA';
  }

  bool _isExpense(Map<String, dynamic> movement) {
    return _getType(movement) == 'DESPESA';
  }

  String _getTitle(Map<String, dynamic> movement) {
    final descricao =
        movement['Descricao'] ?? movement['descricao'];

    if (descricao == null ||
        descricao.toString().trim().isEmpty) {
      return 'Movimentação sem descrição';
    }

    return descricao.toString();
  }

  String _getCategory(Map<String, dynamic> movement) {
    if (_isIncome(movement)) {
      return 'Receita';
    }

    if (_isExpense(movement)) {
      return 'Despesa';
    }

    return 'Tipo não identificado';
  }

  IconData _getIcon(Map<String, dynamic> movement) {
    if (_isIncome(movement)) {
      return Icons.arrow_downward_rounded;
    }

    if (_isExpense(movement)) {
      return Icons.shopping_bag_outlined;
    }

    return Icons.swap_horiz_rounded;
  }

  Color _getColor(Map<String, dynamic> movement) {
    if (_isIncome(movement)) {
      return AppTheme.successColor;
    }

    if (_isExpense(movement)) {
      return AppTheme.errorColor;
    }

    return AppTheme.secondaryTextColor;
  }

  // ============================================================
  // FILTROS E PESQUISA
  // ============================================================

  List<Map<String, dynamic>> get _filteredMovements {
    final search =
        _searchController.text.toLowerCase().trim();

    return _movements.where((movement) {
      final tipo = _getType(movement);

      final matchesFilter = switch (_selectedFilter) {
        1 => tipo == 'RECEITA',
        2 => tipo == 'DESPESA',
        _ => true,
      };

      final title = _getTitle(movement).toLowerCase();
      final category = _getCategory(movement).toLowerCase();

      final matchesSearch =
          title.contains(search) ||
          category.contains(search);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  // ============================================================
  // FORMATAÇÃO
  // ============================================================

  String _formatCurrency(double value) {
    final parts = value.abs().toStringAsFixed(2).split('.');
    final integer = parts[0];

    final formattedInteger = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'R\$ $formattedInteger,${parts[1]}';
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // TELA PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final movements = _filteredMovements;

    final groupedMovements =
        <String, List<Map<String, dynamic>>>{};

    for (final movement in movements) {
      final data = _parseDate(
        movement['DataMovimentacao'] ??
            movement['dataMovimentacao'],
      );

      final month = _formatMonth(data);

      groupedMovements.putIfAbsent(month, () => []);
      groupedMovements[month]!.add(movement);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                14,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Movimentações',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar movimentações',
                    onPressed: _carregarMovimentacoes,
                    icon: const Icon(
                      Icons.refresh,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Filtros
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    _buildFilterButton('Todas', 0),
                    _buildFilterButton('Entradas', 1),
                    _buildFilterButton('Saídas', 2),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Pesquisa
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 21,
                            color: AppTheme.secondaryTextColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Buscar movimentações...',
                                hintStyle: TextStyle(
                                  color:
                                      AppTheme.secondaryTextColor,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 17,
                                color:
                                    AppTheme.secondaryTextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Filtros avançados',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Filtros avançados em breve!',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Lista de movimentações
            Expanded(
              child: _buildContent(
                movements,
                groupedMovements,
              ),
            ),
          ],
        ),
      ),

      // Botão para adicionar movimentação
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNovaMovimentacao,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Nova movimentação',
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ), 
    );
  }

  // ============================================================
  // CONTEÚDO DA LISTA
  // ============================================================

  Widget _buildContent(
    List<Map<String, dynamic>> movements,
    Map<String, List<Map<String, dynamic>>> groupedMovements,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível carregar os dados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _carregarMovimentacoes,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (movements.isEmpty) {
      final mensagem = _movements.isEmpty
          ? 'Nenhuma movimentação cadastrada.'
          : 'Nenhuma movimentação encontrada.';

      return RefreshIndicator(
        onRefresh: _carregarMovimentacoes,
        color: AppTheme.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 350,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        mensagem,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarMovimentacoes,
      color: AppTheme.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          100,
        ),
        children: groupedMovements.entries.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 8,
                ),
                child: Text(
                  group.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              ...group.value.map(_buildMovementItem),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // BOTÕES DE FILTRO
  // ============================================================

  Widget _buildFilterButton(
    String label,
    int index,
  ) {
    final isSelected = _selectedFilter == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : AppTheme.secondaryTextColor,
              fontSize: 13,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ITEM DE MOVIMENTAÇÃO CLICÁVEL
  // ============================================================

  Widget _buildMovementItem(
    Map<String, dynamic> movement,
  ) {
    final tipo = _getType(movement);
    final color = _getColor(movement);

    final valor = _toDouble(
      movement['Valor'] ?? movement['valor'],
    );

    final data = movement['DataMovimentacao'] ??
        movement['dataMovimentacao'];

    final date = _formatDate(data);

    final prefix = tipo == 'RECEITA'
        ? '+'
        : tipo == 'DESPESA'
            ? '-'
            : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirDetalhes(movement),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 4,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor,
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(movement),
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(movement),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$date • ${_getCategory(movement)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$prefix ${_formatCurrency(valor)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}