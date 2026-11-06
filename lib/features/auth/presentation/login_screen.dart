import 'package:flutter/material.dart';
import 'package:finity/core/services/autenticacao_api.dart';
import 'package:finity/core/navigation/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _carregando = false;

  static const Color primaryColor = Color(0xFF4930C8);
  static const Color textColor = Color(0xFF17152A);
  static const Color backgroundColor = Color(0xFFF8F7FC);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Realiza o login na API do Finity.
  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text;

    // Verifica se os campos foram preenchidos.
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o e-mail e a senha.'),
        ),
      );
      return;
    }

    // Impede novas tentativas enquanto a API responde.
    if (_carregando) return;

    setState(() {
      _carregando = true;
    });

    try {
      // Envia as credenciais para a API.
      await AutenticacaoApi.login(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      // Informa que a autenticação foi concluída.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        ),
        (route) => false,
      );

      // A navegação para a tela principal será configurada depois.
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível entrar. Verifique suas credenciais '
            'e tente novamente. Detalhes: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo e nome do Finity.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 75,
                      height: 65,
                      fit: BoxFit.contain,
                    ),
                    const Text(
                      'Finity',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Título.
                const Text(
                  'Bem-vindo de volta!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtítulo.
                const Text(
                  'Faça login para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF858397),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 25),

                // Campo de e-mail.
                const Text(
                  'E-mail',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'seu@email.com',
                    hintStyle: const TextStyle(
                      color: Color(0xFFA6A3B5),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6E4EF),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6E4EF),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Campo de senha.
                const Text(
                  'Senha',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_carregando) {
                      _fazerLogin();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    hintStyle: const TextStyle(
                      color: Color(0xFFA6A3B5),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6E4EF),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Color(0xFFE6E4EF),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF858397),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Esqueci minha senha.
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A recuperação de senha será implementada depois.',
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Esqueci minha senha?',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botão Entrar conectado à API.
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primaryColor.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Orientação para novos usuários.
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        'Não tem uma conta? ',
                        style: TextStyle(
                          color: Color(0xFF777489),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Entre em contato com o administrador.',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Fale com o administrador',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}