import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/contas_pagar_api.dart';
import '../../../../core/services/pagamentos_api.dart';

class AccountPayableDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const AccountPayableDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountPayableDetailsScreen> createState() =>
      _AccountPayableDetailsScreenState();
}

class _AccountPayableDetailsScreenState
    extends State<AccountPayableDetailsScreen> {
  static const Color _purple = Color(0xFF6C4AB6);
  static const Color _background = Color(0xFFF7F7FB);
  static const Color _dark = Color(0xFF252238);
  static const Color _muted = Color(0xFF777487);
  static const Color _green = Color(0xFF219653);
  static const Color _red = Color(0xFFEB5757);

  late Map<String, dynamic> _account;
  List<Map<String, dynamic>> _payments = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _account = Map<String, dynamic>.from(widget.account);
    _loadDetails();
  }

  int get _idConta => (_account['id'] as num).toInt();

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          value?.toString().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  String _currency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final buffer = StringBuffer();

    for (var i = 0; i < integer.length; i++) {
      buffer.write(integer[i]);
      final remaining = integer.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }

    return 'R\$ ${buffer.toString()},${parts[1]}';
  }

  String _date(dynamic value) {
    if (value == null) return '—';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String get _status {
    final situation = (_account['situacao'] ?? 'Pendente')
        .toString()
        .toLowerCase();
    final canceled = _account['cancelada'] == true ||
        situation.contains('cancel');

    if (canceled) return 'Cancelada';
    if (situation.contains('paga')) return 'Paga';
    if (situation.contains('parcial')) return 'Parcial';

    final balance = _number(_account['saldoPendente']);
    final original = _number(_account['valorOriginal']);
    final paid = _number(_account['totalPago']);

    if (original > 0 && balance <= 0) return 'Paga';
    if (paid > 0) return 'Parcial';

    final due = DateTime.tryParse(
      (_account['dataVencimento'] ?? '').toString(),
    );
    if (due != null) {
      final now = DateTime.now();
      if (DateTime(due.year, due.month, due.day)
          .isBefore(DateTime(now.year, now.month, now.day))) {
        return 'Vencida';
      }
    }

    return 'Em aberto';
  }

  Color get _statusColor {
    switch (_status) {
      case 'Paga':
        return _green;
      case 'Vencida':
        return _red;
      case 'Parcial':
        return const Color(0xFF2D9CDB);
      case 'Cancelada':
        return Colors.grey;
      default:
        return const Color(0xFFE6A23C);
    }
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = _idConta;
      final results = await Future.wait<List<Map<String, dynamic>>>([
        ContasPagarApi.listar(),
        PagamentosApi.listarPorConta(idContaPagar: id),
      ]);

      final contas = results[0];
      final pagamentos = results[1];

      final contaAtualizada = contas.cast<Map<String, dynamic>?>().firstWhere(
            (conta) => (conta?['id'] as num?)?.toInt() == id,
            orElse: () => null,
          );

      if (contaAtualizada == null) {
        throw Exception('Não foi possível localizar esta conta.');
      }

      if (!mounted) return;
      setState(() {
        _account = Map<String, dynamic>.from(contaAtualizada);
        _payments = pagamentos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _registerPayment() async {
    if (_status == 'Cancelada' || _status == 'Paga' || _isSaving) return;

    final idCategoria = _account['idCategoria'];
    if (idCategoria is! num) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar a categoria da conta.'),
        ),
      );
      return;
    }

    final balance = _number(_account['saldoPendente']);
    if (balance <= 0) return;

    final valueController = TextEditingController(
      text: balance.toStringAsFixed(2).replaceAll('.', ','),
    );
    DateTime paymentDate = DateTime.now();
    String? validationError;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar pagamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo pendente: ${_currency(balance)}',
                  style: const TextStyle(
                    color: _purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: valueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor pago',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: paymentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) {
                      setDialogState(() => paymentDate = selected);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Data: ${_date(paymentDate.toIso8601String())}'),
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    validationError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = valueController.text.trim().replaceAll(' ', '');
                final normalized = text.contains(',')
                    ? text.replaceAll('.', '').replaceAll(',', '.')
                    : text;
                final value = double.tryParse(normalized);

                if (value == null || value <= 0) {
                  setDialogState(
                    () => validationError = 'Informe um valor maior que zero.',
                  );
                  return;
                }
                if (value > balance + 0.001) {
                  setDialogState(
                    () => validationError =
                        'O valor não pode ser maior que o saldo pendente.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      valueController.dispose();
      return;
    }

    final text = valueController.text.trim().replaceAll(' ', '');
    final normalized = text.contains(',')
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text;
    final value = double.parse(normalized);
    valueController.dispose();

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final idEmpresa = prefs.getInt('idEmpresa') ?? _account['idEmpresa'];
      final idUsuario = prefs.getInt('idUsuario');

      if (idEmpresa is! num || idUsuario == null) {
        throw Exception('Sessão inválida. Entre novamente no aplicativo.');
      }

      await PagamentosApi.criar(
        idContaPagar: _idConta,
        idCategoria: idCategoria.toInt(),
        idCentroCusto: _account['idCentroCusto'] is num
            ? (_account['idCentroCusto'] as num).toInt()
            : null,
        valorPago: value,
        dataPagamento: paymentDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento registrado com sucesso!'),
          backgroundColor: _green,
        ),
      );
      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final description =
        (_account['descricao'] ?? _account['description'] ?? 'Conta a pagar')
            .toString();
    final original = _number(
      _account['valorOriginal'] ?? _account['amount'],
    );
    final totalPaid = _number(_account['totalPago']);
    final balance = _number(_account['saldoPendente']);
    final category = (_account['nomeCategoria'] ??
            _account['categoria'] ??
            'Categoria ${_account['idCategoria'] ?? ''}')
        .toString();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(color: _dark),
        title: const Text(
          'Detalhes da conta',
          style: TextStyle(color: _dark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : _loadDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: _red,
                        ),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDetails,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetails,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: _dark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category,
                              style: const TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _status,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _infoRow('Valor original', _currency(original)),
                            _infoRow(
                              'Data de emissão',
                              _date(_account['dataEmissao']),
                            ),
                            _infoRow(
                              'Data de vencimento',
                              _date(_account['dataVencimento']),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _valueCard(
                              'Total pago',
                              _currency(totalPaid),
                              _green,
                              Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _valueCard(
                              'Saldo pendente',
                              _currency(balance),
                              _purple,
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Histórico de pagamentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_payments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Ainda não existem pagamentos para esta conta.',
                            style: TextStyle(color: _muted),
                          ),
                        )
                      else
                        ..._payments.map((payment) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFFCE8E8),
                                  child: Icon(
                                    Icons.north_east,
                                    color: _red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _date(payment['dataPagamento']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _dark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Pagamento #${payment['id'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _currency(_number(payment['valorPago'])),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 18),
                      if (balance > 0 &&
                          _status != 'Cancelada' &&
                          _status != 'Paga')
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _registerPayment,
                            style: FilledButton.styleFrom(
                              backgroundColor: _purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.payments_outlined),
                            label: Text(
                              _isSaving ? 'Registrando...' : 'Registrar pagamento',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: _muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: _dark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
