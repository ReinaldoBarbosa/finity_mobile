import 'package:flutter/material.dart';

import '../../../core/services/contas_receber_api.dart';
import '../../../core/services/recebimentos_api.dart';

class AccountReceivableDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const AccountReceivableDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountReceivableDetailsScreen> createState() =>
      _AccountReceivableDetailsScreenState();
}

class _AccountReceivableDetailsScreenState
    extends State<AccountReceivableDetailsScreen> {
  static const Color _purple = Color(0xFF6C4AB6);
  static const Color _background = Color(0xFFF7F7FB);

  late Map<String, dynamic> _account;

  List<Map<String, dynamic>> _recebimentos = [];

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

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
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
    final situacao = (_account['situacao'] ?? 'Pendente')
        .toString()
        .toLowerCase();

    if (situacao.contains('cancel')) return 'Cancelada';

    if (situacao.contains('vencid')) return 'Vencida';

    if (situacao.contains('recebid') &&
        !situacao.contains('parcial')) {
      return 'Recebida';
    }

    if (situacao.contains('parcial')) return 'Parcial';

    final saldo = _number(_account['saldoPendente']);
    final valor = _number(_account['valorOriginal']);
    final total = _number(_account['totalRecebido']);

    if (saldo <= 0 && valor > 0) return 'Recebida';
    if (total > 0) return 'Parcial';

    return 'Em aberto';
  }

  Color get _statusColor {
    switch (_status) {
      case 'Recebida':
        return const Color(0xFF219653);
      case 'Vencida':
        return const Color(0xFFEB5757);
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
      // Atualiza os dados da conta usando a listagem já existente.
      // Assim não precisamos alterar o serviço atual de contas a receber.
      final contas = await ContasReceberApi.listar();

      final contaAtualizada = contas.cast<Map<String, dynamic>?>().firstWhere(
            (conta) => conta?['id'] == _idConta,
            orElse: () => null,
          );

      if (contaAtualizada == null) {
        throw Exception('Não foi possível localizar esta conta.');
      }

      final historico = await RecebimentosApi.listarPorConta(
        idContaReceber: _idConta,
      );

      if (!mounted) return;

      setState(() {
        _account = Map<String, dynamic>.from(contaAtualizada);
        _recebimentos = historico;
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

  Future<void> _registrarRecebimento() async {
    if (_status == 'Cancelada' || _status == 'Recebida') return;

    final idCategoria = _account['idCategoria'];

    if (idCategoria is! num) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar a categoria da conta.'),
        ),
      );
      return;
    }

    final saldo = _number(_account['saldoPendente']);

    final valorController = TextEditingController(
      text: saldo.toStringAsFixed(2).replaceAll('.', ','),
    );

    DateTime dataRecebimento = DateTime.now();

    String? erroValidacao;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar recebimento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo pendente: ${_currency(saldo)}',
                      style: const TextStyle(
                        color: Color(0xFF6C4AB6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: valorController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor recebido',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final escolhida = await showDatePicker(
                          context: context,
                          initialDate: dataRecebimento,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (escolhida != null) {
                          setDialogState(() {
                            dataRecebimento = escolhida;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'Data: ${_date(dataRecebimento.toIso8601String())}',
                      ),
                    ),
                    if (erroValidacao != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        erroValidacao!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
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
                    final texto = valorController.text
                        .trim()
                        .replaceAll(' ', '');

                    // Aceita formatos como 1500,50 ou 1.500,50.
                    final normalizado = texto.contains(',')
                        ? texto.replaceAll('.', '').replaceAll(',', '.')
                        : texto;

                    final valor = double.tryParse(normalizado);

                    if (valor == null || valor <= 0) {
                      setDialogState(() {
                        erroValidacao =
                            'Informe um valor maior que zero.';
                      });
                      return;
                    }

                    if (valor > saldo + 0.001) {
                      setDialogState(() {
                        erroValidacao =
                            'O valor não pode ser maior que o saldo pendente.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmado != true || !mounted) {
      valorController.dispose();
      return;
    }

    final texto = valorController.text
        .trim()
        .replaceAll(' ', '');

    final normalizado = texto.contains(',')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto;

    final valor = double.parse(normalizado);

    valorController.dispose();

    setState(() {
      _isSaving = true;
    });

    try {
      await RecebimentosApi.criar(
        idContaReceber: _idConta,
        idCategoria: idCategoria.toInt(),
        idCentroCusto: _account['idCentroCusto'] is num
            ? (_account['idCentroCusto'] as num).toInt()
            : null,
        valorRecebido: valor,
        dataRecebimento: dataRecebimento,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recebimento registrado com sucesso!'),
          backgroundColor: Color(0xFF219653),
        ),
      );

      await _loadDetails();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: const Color(0xFFEB5757),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final descricao =
        (_account['descricao'] ?? 'Conta a receber').toString();

    final valorOriginal = _number(_account['valorOriginal']);
    final totalRecebido = _number(_account['totalRecebido']);
    final saldoPendente = _number(_account['saldoPendente']);

    final categoria = (_account['nomeCategoria'] ??
            _account['categoria'] ??
            'Categoria ${_account['idCategoria'] ?? ''}')
        .toString();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF252238)),
        title: const Text(
          'Detalhes da conta',
          style: TextStyle(
            color: Color(0xFF252238),
            fontWeight: FontWeight.bold,
          ),
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
          ? const Center(
              child: CircularProgressIndicator(color: _purple),
            )
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
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
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
                              descricao,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF252238),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              categoria,
                              style: const TextStyle(
                                color: Color(0xFF777487),
                              ),
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
                            _infoRow(
                              'Valor original',
                              _currency(valorOriginal),
                            ),
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
                              'Total recebido',
                              _currency(totalRecebido),
                              const Color(0xFF219653),
                              Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _valueCard(
                              'Saldo pendente',
                              _currency(saldoPendente),
                              _purple,
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Histórico de recebimentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF252238),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_recebimentos.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Ainda não existem recebimentos para esta conta.',
                            style: TextStyle(
                              color: Color(0xFF777487),
                            ),
                          ),
                        )
                      else
                        ..._recebimentos.map((recebimento) {
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
                                  backgroundColor: Color(0xFFE8F5EC),
                                  child: Icon(
                                    Icons.south_west,
                                    color: Color(0xFF219653),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _date(
                                          recebimento['dataRecebimento'],
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF252238),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Recebimento #${recebimento['id'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF777487),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _currency(
                                    _number(recebimento['valorRecebido']),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF219653),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 18),
                      if (saldoPendente > 0 && _status != 'Cancelada')
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _isSaving
                                ? null
                                : _registrarRecebimento,
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
                              _isSaving
                                  ? 'Registrando...'
                                  : 'Registrar recebimento',
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
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF777487),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF252238),
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
            style: const TextStyle(
              color: Color(0xFF777487),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF252238),
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