import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MovimentacaoApi {
  static const String _baseUrl =
      'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  static Future<String> _obterToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Sua sessão expirou. Entre novamente no aplicativo.',
      );
    }

    return token;
  }

  static Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Exception _erroHttp(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return Exception(
        'Acesso não autorizado. Entre novamente no aplicativo.',
      );
    }

    return Exception(
      'Não foi possível concluir a operação. Código HTTP: $statusCode.',
    );
  }

  static dynamic _decodificarResposta(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw Exception('A API retornou uma resposta inválida.');
    }
  }

  static Future<List<Map<String, dynamic>>> listar() async {
    final token = await _obterToken();

    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/movimentacoes'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw _erroHttp(response.statusCode);
    }

    if (response.statusCode != 200) {
      throw _erroHttp(response.statusCode);
    }

    final dados = _decodificarResposta(response);

    if (dados is! List) {
      throw Exception(
        'A API retornou um formato inesperado para as movimentações.',
      );
    }

    return dados.map<Map<String, dynamic>>((item) {
      if (item is! Map) {
        throw Exception(
          'A API retornou uma movimentação em formato inválido.',
        );
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Future<Map<String, dynamic>> buscarPorId(int id) async {
    final token = await _obterToken();

    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/movimentacoes/$id'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw _erroHttp(response.statusCode);
    }

    if (response.statusCode == 404) {
      throw Exception('Movimentação não encontrada.');
    }

    if (response.statusCode != 200) {
      throw _erroHttp(response.statusCode);
    }

    final dados = _decodificarResposta(response);

    if (dados is! Map) {
      throw Exception(
        'A API retornou um formato inesperado para a movimentação.',
      );
    }

    return Map<String, dynamic>.from(dados);
  }

  static Future<void> estornar(
    int id, {
    String? motivo,
  }) async {
    final token = await _obterToken();

    // O endpoint atual da API é POST /api/movimentacoes/{id}/estornar.
    // O motivo só será enviado se a API aceitar esse campo no corpo.
    final Map<String, dynamic> corpo = {};

    if (motivo != null && motivo.trim().isNotEmpty) {
      corpo['motivoCancelamento'] = motivo.trim();
    }

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/movimentacoes/$id/estornar'),
          headers: _headers(token),
          body: jsonEncode(corpo),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw _erroHttp(response.statusCode);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _erroHttp(response.statusCode);
    }
  }
}