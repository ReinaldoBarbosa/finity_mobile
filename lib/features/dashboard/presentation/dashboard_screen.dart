import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/dashboard_api.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenAccountsPayable;
  final VoidCallback? onOpenAccountsReceivable;

  const DashboardScreen({
    super.key,
    this.onOpenAccountsPayable,
    this.onOpenAccountsReceivable,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryColor = Color(0xFF4930C8);
  static const Color textColor = Color(0xFF211D3A);
  static const Color backgroundColor = Color(0xFFF8F7FC);

  static const List<Color> _coresCategorias = [
    Color(0xFF365EBF),
    Color(0xFFE8B44A),
    Color(0xFF47A99A),
    Color(0xFFE77B62),
    Color(0xFF8A72C8),
    Color(0xFF36A2EB),
    Color(0xFFB56576),
  ];

  bool _showBalance = true;
  bool _carregandoUsuario = true;
  bool _carregandoDados = true;

  String _nomeUsuario = '';
  String? _erro;

  Map<String, dynamic> _resumo = {};
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _movimentacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarNomeUsuario();
    _carregarDashboard();
  }

  // Recupera o nome salvo durante o login.
  Future<void> _carregarNomeUsuario() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final nome = preferencias.getString('nome') ?? '';

      if (!mounted) return;

      setState(() {
        _nomeUsuario = nome.trim();
        _carregandoUsuario = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregandoUsuario = false;
      });
    }
  }

  // Carrega o resumo, as categorias e as movimentações.
  Future<void> _carregarDashboard() async {
    setState(() {
      _carregandoDados = true;
      _erro = null;
    });

    try {
      final resultados = await Future.wait<dynamic>([
        DashboardApi.obterResumo(),
        DashboardApi.obterDespesasPorCategoria(),
        DashboardApi.obterMovimentacoesRecentes(),
      ]);

      if (!mounted) return;

      setState(() {
        _resumo = resultados[0] as Map<String, dynamic>;
        _categorias = resultados[1] as List<Map<String, dynamic>>;
        _movimentacoes = resultados[2] as List<Map<String, dynamic>>;
        _carregandoDados = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregandoDados = false;
      });
    }
  }

  String _obterCumprimento() {
    final hora = DateTime.now().hour;

    if (hora >= 5 && hora < 12) {
      return 'Bom dia';
    } else if (hora >= 12 && hora < 18) {
      return 'Boa tarde';
    }

    return 'Boa noite';
  }

  String _obterPrimeiroNome() {
    if (_nomeUsuario.isEmpty) {
      return 'usuário';
    }

    return _nomeUsuario.split(RegExp(r'\s+')).first;
  }

  // Converte valores numéricos da API para reais brasileiros.
  String _formatarMoeda(dynamic valor) {
    num numero;

    if (valor is num) {
      numero = valor;
    } else {
      numero = num.tryParse(valor?.toString() ?? '') ?? 0;
    }

    final negativo = numero < 0;
    final partes = numero.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final decimal = partes[1];

    final buffer = StringBuffer();

    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(inteiro[i]);
    }

    return '${negativo ? '-' : ''}R\$ ${buffer.toString()},$decimal';
  }

  num _numero(dynamic valor) {
    if (valor is num) return valor;

    return num.tryParse(valor?.toString() ?? '') ?? 0;
  }

  String _obterTexto(Map<String, dynamic> dados, String chave) {
    return dados[chave]?.toString() ?? '';
  }

  String _formatarData(dynamic valor) {
    if (valor == null) return '';

    final data = DateTime.tryParse(valor.toString());

    if (data == null) {
      return valor.toString();
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes';
  }

  String _formatarTipo(String tipo) {
    final tipoNormalizado = tipo.toUpperCase();

    if (tipoNormalizado.contains('RECEITA')) return 'Receita';
    if (tipoNormalizado.contains('DESPESA')) return 'Despesa';

    return tipo.isEmpty ? 'Movimentação' : tipo;
  }

  bool _ehReceita(Map<String, dynamic> movimentacao) {
    final tipo = _obterTexto(movimentacao, 'tipo').toUpperCase();

    return tipo.contains('RECEITA');
  }

  IconData _obterIcone(Map<String, dynamic> movimentacao) {
    final tipo = _obterTexto(movimentacao, 'tipo').toUpperCase();
    final categoria =
        _obterTexto(movimentacao, 'categoria').toLowerCase();

    if (tipo.contains('RECEITA')) {
      return Icons.attach_money_rounded;
    }

    if (categoria.contains('transporte')) {
      return Icons.directions_car_outlined;
    }

    if (categoria.contains('alimentação') ||
        categoria.contains('alimentacao')) {
      return Icons.restaurant_outlined;
    }

    if (categoria.contains('material')) {
      return Icons.shopping_bag_outlined;
    }

    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 22),

                if (_carregandoDados)
                  const LinearProgressIndicator(
                    color: primaryColor,
                    minHeight: 3,
                  ),

                if (_erro != null) ...[
                  _buildErro(),
                  const SizedBox(height: 16),
                ],

                _buildBalanceCard(),

                const SizedBox(height: 16),

                _buildFinancialSummary(),

                const SizedBox(height: 18),

                _buildAccountShortcuts(),

                const SizedBox(height: 24),

                _buildSectionTitle('Gastos por categoria'),

                const SizedBox(height: 14),

                _buildCategorySection(),

                const SizedBox(height: 26),

                _buildSectionTitle(
                  'Últimas movimentações',
                  action: 'Atualizar',
                  onAction: _carregarDashboard,
                ),

                const SizedBox(height: 12),

                _buildRecentTransactions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _carregandoUsuario
                    ? 'Olá! 👋'
                    : '${_obterCumprimento()}, ${_obterPrimeiroNome()}! 👋',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Aqui está o resumo financeiro da sua empresa.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            _showMessage('Configurações em breve.');
          },
          icon: const Icon(
            Icons.tune_rounded,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildErro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Não foi possível carregar os dados.',
            style: TextStyle(
              color: Color(0xFFB42332),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _erro!,
            style: const TextStyle(
              color: Color(0xFF8B2632),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _carregarDashboard,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final saldo = _numero(_resumo['saldo']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 19,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4930C8),
            Color(0xFF6548D7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo atual',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showBalance = !_showBalance;
                  });
                },
                icon: Icon(
                  _showBalance
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _showBalance
                ? _formatarMoeda(saldo)
                : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final receitas = _numero(_resumo['totalReceitas']);
    final despesas = _numero(_resumo['totalDespesas']);
    final saldo = _numero(_resumo['saldo']);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Entradas',
            amount: _formatarMoeda(receitas),
            amountColor: const Color(0xFF259B70),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Saídas',
            amount: _formatarMoeda(despesas),
            amountColor: const Color(0xFFD94D5C),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Saldo',
            amount: _formatarMoeda(saldo),
            amountColor: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountShortcuts() {
    return Row(
      children: [
        Expanded(
          child: _buildAccountShortcut(
            title: 'Contas a Pagar',
            subtitle: 'Gerencie despesas',
            icon: Icons.arrow_upward_rounded,
            iconColor: const Color(0xFFD94D5C),
            backgroundColor: const Color(0xFFFFE9EB),
            onTap: widget.onOpenAccountsPayable ??
                () => _showMessage('Acesso a Contas a Pagar em breve.'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildAccountShortcut(
            title: 'Contas a Receber',
            subtitle: 'Acompanhe receitas',
            icon: Icons.arrow_downward_rounded,
            iconColor: const Color(0xFF259B70),
            backgroundColor: const Color(0xFFE8F7EF),
            onTap: widget.onOpenAccountsReceivable ??
                () => _showMessage('Acesso a Contas a Receber em breve.'),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountShortcut({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEDEBF5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 19,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF777489),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF777489),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEDEBF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF777489),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: amountColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection() {
    if (_carregandoDados && _categorias.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    if (_categorias.isEmpty) {
      return _buildEmptyCard(
        'Nenhuma despesa por categoria encontrada.',
      );
    }

    final total = _categorias.fold<num>(
      0,
      (soma, item) => soma + _numero(item['total']),
    );

    final valores = _categorias
        .map((item) => _numero(item['total']).toDouble())
        .toList();

    final cores = List<Color>.generate(
      _categorias.length,
      (index) => _coresCategorias[index % _coresCategorias.length],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEDEBF5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            height: 105,
            child: CustomPaint(
              painter: _CategoryChartPainter(
                values: valores,
                colors: cores,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_categorias.length, (index) {
                final categoria = _categorias[index];
                final nome =
                    _obterTexto(categoria, 'categoria').isEmpty
                        ? 'Sem categoria'
                        : _obterTexto(categoria, 'categoria');

                final valor = _numero(categoria['total']);

                final percentual = total > 0
                    ? (valor / total * 100).round()
                    : 0;

                return _CategoryLegend(
                  color: cores[index],
                  name: nome,
                  percentage: '$percentual%',
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_carregandoDados && _movimentacoes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    if (_movimentacoes.isEmpty) {
      return _buildEmptyCard(
        'Nenhuma movimentação recente encontrada.',
      );
    }

    return Column(
      children: _movimentacoes.map((movimentacao) {
        final receita = _ehReceita(movimentacao);
        final valor = _numero(movimentacao['valor']);
        final descricao =
            _obterTexto(movimentacao, 'descricao').isEmpty
                ? 'Movimentação'
                : _obterTexto(movimentacao, 'descricao');

        final categoria = _obterTexto(movimentacao, 'categoria');
        final data = _formatarData(movimentacao['dataMovimentacao']);
        final cancelada = movimentacao['cancelada'] == true;

        final subtitulo = [
          if (data.isNotEmpty) data,
          if (categoria.isNotEmpty) categoria,
          if (cancelada) 'Cancelada',
        ].join(' · ');

        final valorFormatado = _formatarMoeda(valor.abs());
        final valorComSinal = cancelada
            ? valorFormatado
            : '${receita ? '+' : '-'} $valorFormatado';

        return Opacity(
          opacity: cancelada ? 0.55 : 1,
          child: _buildTransaction(
            icon: _obterIcone(movimentacao),
            title: descricao,
            subtitle: subtitulo.isEmpty
                ? _formatarTipo(
                    _obterTexto(movimentacao, 'tipo'),
                  )
                : subtitulo,
            amount: valorComSinal,
            isIncome: receita,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyCard(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEDEBF5),
        ),
      ),
      child: Text(
        mensagem,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF777489),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTransaction({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
  }) {
    final Color amountColor = isIncome
        ? const Color(0xFF259B70)
        : const Color(0xFFD94D5C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isIncome
                  ? const Color(0xFFE8F7EF)
                  : const Color(0xFFFFE9EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF89869B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: amountColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final Color color;
  final String name;
  final String percentage;

  const _CategoryLegend({
    required this.color,
    required this.name,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF777489),
                fontSize: 9,
              ),
            ),
          ),
          Text(
            percentage,
            style: const TextStyle(
              color: Color(0xFF514D65),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _CategoryChartPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.butt;

    final total = values.fold<double>(
      0,
      (soma, valor) => soma + (valor > 0 ? valor : 0),
    );

    if (total <= 0 || values.isEmpty) {
      paint.color = const Color(0xFFEDEBF5);
      canvas.drawArc(
        rect.deflate(8),
        0,
        6.28318,
        false,
        paint,
      );
      return;
    }

    double startAngle = -1.5708;

    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;

      paint.color = colors[i];

      final sweepAngle = values[i] / total * 6.28318;

      canvas.drawArc(
        rect.deflate(8),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length ||
        oldDelegate.colors.length != colors.length) {
      return true;
    }

    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i] ||
          oldDelegate.colors[i] != colors[i]) {
        return true;
      }
    }

    return false;
  }
}