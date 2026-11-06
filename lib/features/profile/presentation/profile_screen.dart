import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nome = 'Usuário';
  String _email = 'E-mail não informado';
  String _nomeEmpresa = 'Minha empresa';
  String _idEmpresa = '';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _nome = prefs.getString('nomeUsuario') ??
          prefs.getString('nome') ??
          'Usuário';

      _email = prefs.getString('emailUsuario') ??
          prefs.getString('email') ??
          'E-mail não informado';

      _nomeEmpresa = prefs.getString('nomeEmpresa') ??
          'Minha empresa';

      _idEmpresa = prefs.getInt('idEmpresa')?.toString() ??
          prefs.getString('idEmpresa') ??
          '';

      _carregando = false;
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmarSaida() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Sair da conta?'),
          content: const Text(
            'Deseja realmente encerrar sua sessão?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    // Remove apenas os dados de autenticação.
    // A navegação para o login será conectada à tela
    // de autenticação existente no projeto.
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('idUsuario');
    await prefs.remove('idEmpresa');

    if (!mounted) return;

    _mostrarMensagem(
      'Sessão encerrada. Conecte a tela de login para continuar.',
    );
  }

  void _abrirOpcao(String titulo) {
    _mostrarMensagem(
      '$titulo: vamos conectar esta funcionalidade.',
    );
  }

  Widget _secao(String titulo, List<Widget> itens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 2,
            bottom: 12,
          ),
          child: Text(
            titulo,
            style: const TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.borderColor,
            ),
          ),
          child: Column(children: itens),
        ),
      ],
    );
  }

  Widget _item({
    required IconData icone,
    required Color cor,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    bool ultimo = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icone,
                    color: cor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.secondaryTextColor,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
        if (!ultimo)
          Padding(
            padding: const EdgeInsets.only(left: 76),
            child: Divider(
              height: 1,
              color: AppTheme.borderColor,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () => _abrirOpcao('Configurações'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  28,
                ),
                children: [
                  // Dados do usuário
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppTheme.primaryColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Minha conta',
                                style: TextStyle(
                                  color:
                                      AppTheme.secondaryTextColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color:
                                        AppTheme.secondaryTextColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme
                                            .secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Empresa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: AppTheme.primaryColor,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nomeEmpresa,
                                style: const TextStyle(
                                  color: AppTheme.textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _idEmpresa.isEmpty
                                    ? 'Empresa selecionada'
                                    : 'Código: $_idEmpresa',
                                style: const TextStyle(
                                  color:
                                      AppTheme.secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _secao('Conta', [
                    _item(
                      icone: Icons.lock_outline_rounded,
                      cor: AppTheme.primaryColor,
                      titulo: 'Alterar senha',
                      subtitulo: 'Mantenha sua conta segura',
                      onTap: () =>
                          _abrirOpcao('Alterar senha'),
                    ),
                    _item(
                      icone: Icons.verified_user_outlined,
                      cor: AppTheme.successColor,
                      titulo: 'Segurança',
                      subtitulo: 'Opções de segurança da conta',
                      onTap: () => _abrirOpcao('Segurança'),
                      ultimo: true,
                    ),
                  ]),

                  const SizedBox(height: 22),

                  _secao('Empresa', [
                    _item(
                      icone: Icons.groups_rounded,
                      cor: const Color(0xFF7047EB),
                      titulo: 'Departamentos',
                      subtitulo:
                          'Gerencie os departamentos da empresa',
                      onTap: () =>
                          _abrirOpcao('Departamentos'),
                    ),
                    _item(
                      icone: Icons.sell_outlined,
                      cor: AppTheme.warningColor,
                      titulo: 'Categorias',
                      subtitulo:
                          'Organize receitas e despesas',
                      onTap: () => _abrirOpcao('Categorias'),
                      ultimo: true,
                    ),
                  ]),

                  const SizedBox(height: 22),

                  _secao('Configurações', [
                    _item(
                      icone: Icons.notifications_none_rounded,
                      cor: AppTheme.infoColor,
                      titulo: 'Notificações',
                      subtitulo: 'Configure seus alertas',
                      onTap: () =>
                          _abrirOpcao('Notificações'),
                    ),
                    _item(
                      icone: Icons.palette_outlined,
                      cor: const Color(0xFF7047EB),
                      titulo: 'Aparência',
                      subtitulo: 'Personalize o visual do app',
                      onTap: () => _abrirOpcao('Aparência'),
                      ultimo: true,
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // Sair da conta
                  Material(
                    color: AppTheme.errorColor.withValues(
                      alpha: 0.07,
                    ),
                    borderRadius: BorderRadius.circular(17),
                    child: InkWell(
                      onTap: _confirmarSaida,
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(17),
                          border: Border.all(
                            color: AppTheme.errorColor.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                'Sair da conta',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.errorColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Center(
                    child: Text(
                      'Finity • v1.0.0',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}