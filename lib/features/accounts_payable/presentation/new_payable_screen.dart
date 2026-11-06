import 'package:flutter/material.dart';

import '../../../../core/services/contas_pagar_api.dart';
import '../../../../core/theme/app_theme.dart';

class NewPayableScreen extends StatefulWidget {
  const NewPayableScreen({super.key});

  @override
  State<NewPayableScreen> createState() => _NewPayableScreenState();
}

class _NewPayableScreenState extends State<NewPayableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();

  // Mantido conforme a implementação atual.
  // Posteriormente, podemos obter o ID da empresa pela sessão.
  static const int _idEmpresa = 1;

  int? _selectedCategoryId;

  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;

  List<Map<String, dynamic>> _categories = [];

  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final categorias = await ContasPagarApi.listarCategorias();

      final validas = categorias.where((categoria) {
        final tipo = categoria['tipo']?.toString().toUpperCase();
        final ativa = categoria['ativo'] == true;
        final empresaId = categoria['idEmpresa'];

        return tipo == 'DESPESA' &&
            ativa &&
            empresaId is num &&
            empresaId.toInt() == _idEmpresa;
      }).toList();

      if (!mounted) return;

      setState(() {
        _categories = validas;
        _isLoadingCategories = false;
        _categoryError = validas.isEmpty
            ? 'Nenhuma categoria ativa de despesa foi encontrada para esta empresa.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _categoryError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingCategories = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Selecionar data';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _selectDate({required bool isIssueDate}) async {
    final initialDate = isIssueDate
        ? _issueDate
        : (_dueDate ?? _issueDate);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: isIssueDate ? 'Data de emissão' : 'Data de vencimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      if (isIssueDate) {
        _issueDate = selectedDate;
      } else {
        _dueDate = selectedDate;
      }
    });
  }

  double? _parseValue(String value) {
    var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (normalized.isEmpty) return null;

    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(normalized);
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? AppTheme.successColor
              : AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  Future<void> _saveAccount() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showMessage('Selecione uma categoria.');
      return;
    }

    if (_dueDate == null) {
      _showMessage('Selecione a data de vencimento.');
      return;
    }

    final emissao = DateTime(
      _issueDate.year,
      _issueDate.month,
      _issueDate.day,
    );

    final vencimento = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
    );

    if (vencimento.isBefore(emissao)) {
      _showMessage(
        'A data de vencimento não pode ser anterior à emissão.',
      );
      return;
    }

    final valor = _parseValue(_valueController.text);

    if (valor == null || valor <= 0) {
      _showMessage('Informe um valor válido maior que zero.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ContasPagarApi.criar(
        idEmpresa: _idEmpresa,
        idCategoria: _selectedCategoryId!,
        descricao: _descriptionController.text.trim(),
        valorOriginal: valor,
        dataEmissao: _issueDate,
        dataVencimento: _dueDate!,
      );

      if (!mounted) return;

      _showMessage(
        'Conta a pagar cadastrada com sucesso!',
        success: true,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Não foi possível salvar a conta: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _decoration(
          label,
          icon: Icons.calendar_today_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  color: date == null
                      ? AppTheme.secondaryTextColor
                      : AppTheme.textColor,
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

  Widget _categoryField() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categoryError != null) {
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
              _categoryError!,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      isExpanded: true,
      decoration: _decoration(
        'Categoria da despesa',
        icon: Icons.category_outlined,
      ),
      hint: const Text('Selecione uma categoria'),
      items: _categories.map((categoria) {
        final id = (categoria['id'] as num).toInt();

        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            categoria['nome']?.toString() ?? 'Categoria $id',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Selecione uma categoria.';
        }

        return null;
      },
      onChanged: _isSaving
          ? null
          : (value) {
              setState(() => _selectedCategoryId = value);
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nova conta a pagar'),
        leading: IconButton(
          onPressed: _isSaving
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
                      Icons.north_east_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova despesa',
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cadastre um valor que sua empresa precisa pagar.',
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

              _sectionTitle(
                'Dados da conta',
                'Informe a descrição e o valor da despesa.',
              ),

              TextFormField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLength: 255,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  'Descrição',
                  hint: 'Ex.: Conta de energia',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a descrição.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _valueController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration(
                  'Valor (R\$)',
                  hint: '0,00',
                  icon: Icons.attach_money,
                ),
                validator: (value) {
                  final parsed = _parseValue(value ?? '');

                  if (parsed == null || parsed <= 0) {
                    return 'Informe um valor válido maior que zero.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              _sectionTitle(
                'Classificação',
                'Selecione a categoria que representa esta despesa.',
              ),

              _categoryField(),

              const SizedBox(height: 28),

              _sectionTitle(
                'Datas',
                'Defina a emissão e o vencimento da conta.',
              ),

              _dateField(
                label: 'Data de emissão',
                date: _issueDate,
                onTap: () => _selectDate(isIssueDate: true),
              ),

              const SizedBox(height: 16),

              _dateField(
                label: 'Data de vencimento',
                date: _dueDate,
                onTap: () => _selectDate(isIssueDate: false),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ||
                          _isLoadingCategories ||
                          _categoryError != null
                      ? null
                      : _saveAccount,
                  icon: _isSaving
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
                    _isSaving
                        ? 'Salvando...'
                        : 'Salvar conta a pagar',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSaving
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
