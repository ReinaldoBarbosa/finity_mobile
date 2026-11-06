import 'package:flutter/material.dart';

import '../../../../core/services/categorias_api.dart';
import '../../../../core/services/contas_receber_api.dart';
import '../../../../core/theme/app_theme.dart';

class NewReceivableScreen extends StatefulWidget {
  const NewReceivableScreen({super.key});

  @override
  State<NewReceivableScreen> createState() => _NewReceivableScreenState();
}

class _NewReceivableScreenState extends State<NewReceivableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  List<Map<String, dynamic>> _categorias = [];
  int? _categoriaSelecionada;

  DateTime _dataEmissao = DateTime.now();
  DateTime _dataVencimento = DateTime.now().add(
    const Duration(days: 30),
  );

  bool _carregandoCategorias = true;
  bool _salvando = false;
  String? _erroCategorias;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _carregandoCategorias = true;
      _erroCategorias = null;
    });

    try {
      final categorias = await CategoriasApi.listarReceitas();

      if (!mounted) return;

      setState(() {
        _categorias = categorias;
        _carregandoCategorias = false;
        _erroCategorias = categorias.isEmpty
            ? 'Nenhuma categoria de receita ativa foi encontrada.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregandoCategorias = false;
        _erroCategorias = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  Future<void> _selecionarData({required bool emissao}) async {
    final inicial = emissao ? _dataEmissao : _dataVencimento;

    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: emissao ? 'Data de emissão' : 'Data de vencimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (data == null || !mounted) return;

    setState(() {
      if (emissao) {
        _dataEmissao = data;
      } else {
        _dataVencimento = data;
      }
    });
  }

  double? _lerValor(String texto) {
    var valor = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (valor.isEmpty) return null;

    // Aceita valores como 1500,00 e 1.500,00.
    if (valor.contains(',')) {
      valor = valor.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(valor);
  }

  void _mostrarMensagem(
    String mensagem, {
    bool sucesso = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: sucesso
              ? AppTheme.successColor
              : AppTheme.errorColor,
        ),
      );
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSelecionada == null) {
      _mostrarMensagem('Selecione uma categoria.');
      return;
    }

    final emissao = DateTime(
      _dataEmissao.year,
      _dataEmissao.month,
      _dataEmissao.day,
    );

    final vencimento = DateTime(
      _dataVencimento.year,
      _dataVencimento.month,
      _dataVencimento.day,
    );

    if (vencimento.isBefore(emissao)) {
      _mostrarMensagem(
        'A data de vencimento não pode ser anterior à emissão.',
      );
      return;
    }

    final valor = _lerValor(_valorController.text);

    if (valor == null || valor <= 0) {
      _mostrarMensagem('Informe um valor válido maior que zero.');
      return;
    }

    setState(() => _salvando = true);

    try {
      await ContasReceberApi.criar(
        idCategoria: _categoriaSelecionada!,
        descricao: _descricaoController.text.trim(),
        valorOriginal: valor,
        dataEmissao: _dataEmissao,
        dataVencimento: _dataVencimento,
      );

      if (!mounted) return;

      _mostrarMensagem(
        'Conta a receber cadastrada com sucesso!',
        sucesso: true,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  InputDecoration _decoracao(
    String label,
    IconData icone, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icone,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _tituloSecao(String titulo, String subtitulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoData({
    required String titulo,
    required DateTime data,
    required VoidCallback aoTocar,
  }) {
    return InkWell(
      onTap: _salvando ? null : aoTocar,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _decoracao(
          titulo,
          Icons.calendar_today_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatarData(data),
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoCategoria() {
    if (_carregandoCategorias) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erroCategorias != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 8),
            Text(
              _erroCategorias!,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _salvando ? null : _carregarCategorias,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _categoriaSelecionada,
      isExpanded: true,
      decoration: _decoracao(
        'Categoria da receita',
        Icons.category_outlined,
      ),
      hint: const Text('Selecione uma categoria'),
      items: _categorias.map((categoria) {
        final id = int.parse(categoria['id'].toString());

        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            categoria['nome']?.toString() ?? 'Sem nome',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _salvando
          ? null
          : (valor) {
              setState(() => _categoriaSelecionada = valor);
            },
      validator: (valor) {
        if (valor == null) {
          return 'Selecione uma categoria.';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nova conta a receber'),
        leading: IconButton(
          onPressed: _salvando
              ? null
              : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.borderColor,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.south_west_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova receita',
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cadastre um valor que sua empresa tem a receber.',
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _tituloSecao(
                'Dados da conta',
                'Informe a descrição e o valor da receita.',
              ),

              TextFormField(
                controller: _descricaoController,
                enabled: !_salvando,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 255,
                decoration: _decoracao(
                  'Descrição',
                  Icons.description_outlined,
                  hint: 'Ex.: Serviço prestado',
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe a descrição.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _valorController,
                enabled: !_salvando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoracao(
                  'Valor (R\$)',
                  Icons.attach_money,
                  hint: '0,00',
                ),
                validator: (texto) {
                  final valor = _lerValor(texto ?? '');

                  if (valor == null || valor <= 0) {
                    return 'Informe um valor maior que zero.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              _tituloSecao(
                'Classificação',
                'Selecione a categoria que representa esta receita.',
              ),

              _campoCategoria(),

              const SizedBox(height: 28),

              _tituloSecao(
                'Datas',
                'Defina a emissão e o vencimento da receita.',
              ),

              _campoData(
                titulo: 'Data de emissão',
                data: _dataEmissao,
                aoTocar: () => _selecionarData(emissao: true),
              ),

              const SizedBox(height: 16),

              _campoData(
                titulo: 'Data de vencimento',
                data: _dataVencimento,
                aoTocar: () => _selecionarData(emissao: false),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _salvando ||
                          _carregandoCategorias ||
                          _erroCategorias != null
                      ? null
                      : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _salvando
                        ? 'Salvando...'
                        : 'Salvar conta a receber',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _salvando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}