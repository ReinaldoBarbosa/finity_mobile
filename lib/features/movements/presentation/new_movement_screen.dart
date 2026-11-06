import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewMovementScreen extends StatefulWidget {
  const NewMovementScreen({super.key});

  @override
  State<NewMovementScreen> createState() => _NewMovementScreenState();
}

class _NewMovementScreenState extends State<NewMovementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 0 = Receita | 1 = Despesa
  int _selectedType = 1;

  String? _selectedCategory;
  String? _selectedCostCenter;

  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  // Opções temporárias para desenvolver a interface.
  // Depois serão carregadas da API.
  final List<String> _categories = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Lazer',
    'Materiais',
    'Serviços',
    'Salário',
    'Vendas',
    'Outros',
  ];

  final List<String> _costCenters = [
    'Administrativo',
    'Comercial',
    'Financeiro',
    'Operacional',
    'Outros',
  ];

  static const Color _purple = Color(0xFF5136C9);
  static const Color _background = Color(0xFFF8F8FC);
  static const Color _textColor = Color(0xFF30304A);
  static const Color _mutedColor = Color(0xFF9696A9);
  static const Color _green = Color(0xFF2BA875);
  static const Color _red = Color(0xFFE85B65);

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

Future<void> _selectDate() async {
  final date = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    locale: const Locale('pt', 'BR'),
  );

  if (date != null && mounted) {
    setState(() {
      _selectedDate = date;
    });
  }
}

  double? _parseValue(String input) {
    var value = input.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (value.isEmpty) return null;

    // Aceita valores como 1234,56 ou 1.234,56.
    if (value.contains(',')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(value);
  }

  String get _movementType {
    return _selectedType == 0 ? 'RECEITA' : 'DESPESA';
  }

  Future<void> _saveMovement() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final value = _parseValue(_valueController.text);

    if (value == null || value <= 0) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Preparação dos dados para a futura integração com a API.
    // Os IDs reais serão obtidos dos cadastros do back-end.
    final movementData = {
      'IdEmpresa': null,
      'IdCategoria': null,
      'IdCentroCusto': null,
      'IdUsuario': null,
      'Descricao': _descriptionController.text.trim(),
      'Valor': value,
      'Tipo': _movementType,
      'DataMovimentacao':
          '${_selectedDate.year.toString().padLeft(4, '0')}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}',
    };

    // Ainda não enviamos os dados: faltam conectar a API e obter os IDs.
    debugPrint('Dados preparados para movimentação: $movementData');

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Formulário validado! A integração com a API será feita na próxima etapa.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: _textColor,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Nova movimentação',
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _buildLabel('Tipo de movimentação'),
              const SizedBox(height: 10),
              _buildTypeSelector(),

              const SizedBox(height: 22),

              _buildLabel('Valor'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9.,]'),
                  ),
                ],
                decoration: _inputDecoration(
                  hint: 'R\$ 0,00',
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    size: 19,
                    color: _mutedColor,
                  ),
                ),
                validator: (value) {
                  final parsed = _parseValue(value ?? '');

                  if (parsed == null || parsed <= 0) {
                    return 'Informe um valor maior que zero.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 19),

              _buildLabel('Descrição'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _descriptionController,
                maxLength: 255,
                maxLines: 2,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hint: 'Ex.: Compra de materiais',
                ).copyWith(
                  counterText: '',
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe uma descrição.';
                  }

                  if (value.trim().length > 255) {
                    return 'A descrição deve ter até 255 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 19),

              _buildLabel('Categoria'),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: _inputDecoration(
                  hint: 'Selecione a categoria',
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _mutedColor,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione uma categoria.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 19),

              _buildLabel('Centro de custo'),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                value: _selectedCostCenter,
                isExpanded: true,
                decoration: _inputDecoration(
                  hint: 'Selecione o centro de custo (opcional)',
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _mutedColor,
                ),
                items: _costCenters.map((center) {
                  return DropdownMenuItem(
                    value: center,
                    child: Text(
                      center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCostCenter = value;
                  });
                },
              ),

              const SizedBox(height: 19),

              _buildLabel('Data'),
              const SizedBox(height: 9),
              // Campo de data
              InkWell(
                onTap: () async {
                  await _selectDate();
                },
                borderRadius: BorderRadius.circular(12),
                child: IgnorePointer(
                  child: TextFormField(
                    key: ValueKey(_selectedDate),
                    readOnly: true,
                    decoration: _inputDecoration(
                      hint: 'Selecione a data',
                      suffixIcon: const Icon(
                        Icons.calendar_month_outlined,
                        color: _mutedColor,
                        size: 20,
                      ),
                    ),
                    controller: TextEditingController(
                      text: _formatDate(_selectedDate),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMovement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    disabledBackgroundColor: _purple.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Salvar movimentação',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _textColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            title: 'Entrada',
            index: 0,
            icon: Icons.arrow_upward,
            color: _green,
            background: const Color(0xFFEAF8F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            title: 'Saída',
            index: 1,
            icon: Icons.arrow_downward,
            color: _red,
            background: const Color(0xFFFFEFF0),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String title,
    required int index,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    final selected = _selectedType == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.45) : background,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _mutedColor,
        fontSize: 13,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9E9F1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9E9F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _red, width: 1.4),
      ),
    );
  }
}
