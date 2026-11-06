import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AutenticacaoApi {
  static const String baseUrl =
      'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final uri = Uri.parse('$baseUrl/api/autenticacao/login');

    final response = await http
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'email': email,
            'senha': senha,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível entrar. Verifique seu e-mail e senha '
        '(HTTP ${response.statusCode}).',
      );
    }

    final dynamic dados =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! Map<String, dynamic> ||
        dados['token'] == null ||
        dados['token'].toString().isEmpty) {
      throw Exception('A API não retornou um token válido.');
    }

    final preferencias = await SharedPreferences.getInstance();

    await preferencias.setString('token', dados['token'].toString());

    await preferencias.setInt(
      'idUsuario',
      (dados['idUsuario'] as num).toInt(),
    );

    await preferencias.setInt(
      'idEmpresa',
      (dados['idEmpresa'] as num).toInt(),
    );

    await preferencias.setInt(
      'idPerfil',
      (dados['idPerfil'] as num).toInt(),
    );

    await preferencias.setString('nome', dados['nome'].toString());
    await preferencias.setString('email', dados['email'].toString());

    await preferencias.setString(
      'expiraEm',
      dados['expiraEm'].toString(),
    );

    return dados;
  }

  static Future<String?> obterToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('token');
  }
}