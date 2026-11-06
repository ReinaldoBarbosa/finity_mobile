import 'package:flutter/material.dart';

import './../../../core/services/movimentacao_api.dart';
import '../../../core/theme/app_theme.dart';

class MovimentacaoDetalhesScreen extends StatefulWidget {
  final int idMovimentacao;

  const MovimentacaoDetalhesScreen({
    super.key,
    required this.idMovimentacao,
  });

  @override
  State<MovimentacaoDetalhesScreen> createState() =>
      _MovimentacaoDetalhesScreenState();
}

class _MovimentacaoDetalhesScreenState
    extends State<MovimentacaoDetalhesScreen> {
  Map<String, dynamic>? _movimentacao;
  bool _carregando = true;
  bool _estornando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarMovimentacao();
  }

  dynamic _valor(Map<String, dynamic> dados, String chave) {
    if (dados.containsKey(chave)) return dados[chave];

    final chaveMinuscula =
        '${chave[0].toLowerCase()}${chave.substring(1)}';

    return dados[chaveMinuscula];
  }

  String _texto(dynamic valor, {String vazio = 'Não informado'}) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return vazio;
    }

    return valor.toString();
  }
  double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();

    final texto = valor?.toString() ?? '';
    return double.tryParse(texto.replaceAll(',', '.')) ?? 0;
  }

  DateTime? _data(dynamic valor) {
    if (valor is DateTime) return valor;
    if (valor == null) return null;

    return DateTime.tryParse(valor.toString());
  }

  String _formatarData(dynamic valor) {
    final data = _data(valor);

    if (data == null) return 'Não informada';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarDataHora(dynamic valor) {
    final data = _data(valor);

    if (data == null) return 'Não informada';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  String _formatarMoeda(double valor) {
    final negativo = valor < 0;
    final absoluto = valor.abs();
    final partes = absoluto.toStringAsFixed(2).split('.');
    final digitos = partes[0];
    final buffer = StringBuffer();

    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digitos[i]);
    }

    return '${negativo ? '-' : ''}R\$ ${buffer.toString()},${partes[1]}';
  }

  Future<void> _carregarMovimentacao() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await MovimentacaoApi.buscarPorId(
        widget.idMovimentacao,
      );

      if (!mounted) return;

      setState(() {
        _movimentacao = dados;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  Future<void> _confirmarEstorno() async {
    final dados = _movimentacao;
    if (dados == null) return;

    final cancelada = _valor(dados, 'Cancelada') == true;
    final original = _valor(dados, 'IdMovimentacaoOriginal');

    if (cancelada || original != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta movimentação não pode ser estornada novamente.',
          ),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Estornar movimentação?'),
          content: const Text(
            'Essa ação registrará uma movimentação inversa. '
            'Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Confirmar estorno'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() => _estornando = true);

    try {
      await MovimentacaoApi.estornar(widget.idMovimentacao);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimentação estornada com sucesso.'),
        ),
      );

      // Informa à tela anterior que ela deve atualizar a lista.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _estornando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _secao(String titulo, List<Widget> filhos) {
    return Card(
      color: AppTheme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _linha(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              titulo,
              style: const TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    final dados = _movimentacao!;

    final tipo = _texto(
      _valor(dados, 'Tipo'),
      vazio: 'DESPESA',
    ).toUpperCase();

    final receita = tipo == 'RECEITA';
    final corTipo = receita ? AppTheme.successColor : AppTheme.errorColor;
    final cancelada = _valor(dados, 'Cancelada') == true;
    final idOriginal = _valor(dados, 'IdMovimentacaoOriginal');
    final valor = _numero(_valor(dados, 'Valor'));

    final idCategoria = _valor(dados, 'IdCategoria');
    final idCentroCusto = _valor(dados, 'IdCentroCusto');
    final idUsuario = _valor(dados, 'IdUsuario');
    final idEmpresa = _valor(dados, 'IdEmpresa');

    return RefreshIndicator(
      onRefresh: _carregarMovimentacao,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: corTipo.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      receita
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: corTipo,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    receita ? 'Receita' : 'Despesa',
                    style: TextStyle(
                      color: corTipo,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatarMoeda(valor),
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _texto(
                      _valor(dados, 'Descricao'),
                      vazio: 'Sem descrição',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: (cancelada
                              ? AppTheme.cancelledColor
                              : idOriginal != null
                                  ? AppTheme.warningColor
                                  : AppTheme.successColor)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cancelada
                          ? 'Cancelada'
                          : idOriginal != null
                              ? 'Estorno'
                              : 'Ativa',
                      style: TextStyle(
                        color: cancelada
                            ? AppTheme.cancelledColor
                            : idOriginal != null
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _secao(
            'Informações da movimentação',
            [
              _linha(
                'Identificador',
                _texto(_valor(dados, 'Id')),
              ),
              _linha(
                'Data da movimentação',
                _formatarData(_valor(dados, 'DataMovimentacao')),
              ),
              _linha(
                'Data de cadastro',
                _formatarDataHora(_valor(dados, 'DataCadastro')),
              ),
              _linha(
                'Tipo',
                tipo == 'RECEITA' ? 'Receita' : 'Despesa',
              ),
              _linha(
                'Categoria',
                idCategoria == null
                    ? 'Não informada'
                    : 'Categoria #$idCategoria',
              ),
              _linha(
                'Centro de custo',
                idCentroCusto == null
                    ? 'Não informado'
                    : 'Centro de custo #$idCentroCusto',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _secao(
            'Informações adicionais',
            [
              _linha(
                'Empresa',
                idEmpresa == null ? 'Não informada' : '#$idEmpresa',
              ),
              _linha(
                'Usuário responsável',
                idUsuario == null ? 'Não informado' : '#$idUsuario',
              ),
              if (idOriginal != null)
                _linha('Movimentação original', '#$idOriginal'),
              if (_valor(dados, 'DataCancelamento') != null)
                _linha(
                  'Data do cancelamento',
                  _formatarDataHora(
                    _valor(dados, 'DataCancelamento'),
                  ),
                ),
              if (_valor(dados, 'IdUsuarioCancelamento') != null)
                _linha(
                  'Usuário do cancelamento',
                  '#${_valor(dados, 'IdUsuarioCancelamento')}',
                ),
              if (_valor(dados, 'MotivoCancelamento') != null)
                _linha(
                  'Motivo do cancelamento',
                  _texto(_valor(dados, 'MotivoCancelamento')),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!cancelada && idOriginal == null)
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _estornando ? null : _confirmarEstorno,
                icon: _estornando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.undo_rounded),
                label: Text(
                  _estornando ? 'Estornando...' : 'Estornar movimentação',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes da movimentação'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregarMovimentacao,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.errorColor,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _carregarMovimentacao,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _movimentacao == null
                  ? const Center(
                      child: Text('Movimentação não encontrada.'),
                    )
                  : _conteudo(),
    );
  }
}