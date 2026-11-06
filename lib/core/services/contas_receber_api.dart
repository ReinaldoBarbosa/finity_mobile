import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ContasReceberApi {
  static const String _baseUrl =
      'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  static Future<String> _obterToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    return token;
  }

  // NOVO: lista as contas cadastradas na API.
  static Future<List<Map<String, dynamic>>> listar() async {
    final token = await _obterToken();

    final uri = Uri.parse('$_baseUrl/api/contas-receber');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    if (response.statusCode == 403) {
      throw Exception('Você não tem permissão para consultar estas contas.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível carregar as contas '
        '(HTTP ${response.statusCode}).',
      );
    }

    final dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! List) {
      throw Exception('A API retornou uma lista de contas inválida.');
    }

    return dados
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Cadastra uma nova conta.
  static Future<Map<String, dynamic>> criar({
    required int idCategoria,
    required String descricao,
    required double valorOriginal,
    required DateTime dataEmissao,
    required DateTime dataVencimento,
    int? idCentroCusto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _obterToken();
    final idEmpresa = prefs.getInt('idEmpresa');

    if (idEmpresa == null) {
      throw Exception('Não foi possível identificar sua empresa.');
    }

    final uri = Uri.parse('$_baseUrl/api/contas-receber');

    final body = {
      'idEmpresa': idEmpresa,
      'idCategoria': idCategoria,
      'tipoCategoria': 'RECEITA',
      'idCentroCusto': idCentroCusto,
      'descricao': descricao,
      'valorOriginal': valorOriginal,
      'dataEmissao': _formatarData(dataEmissao),
      'dataVencimento': _formatarData(dataVencimento),
    };

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    if (response.statusCode == 403) {
      throw Exception('Você não tem permissão para cadastrar esta conta.');
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      String mensagem =
          'Não foi possível cadastrar a conta (HTTP ${response.statusCode}).';

      try {
        final dados = jsonDecode(utf8.decode(response.bodyBytes));

        if (dados is Map && dados['mensagem'] != null) {
          mensagem = dados['mensagem'].toString();
        }
      } catch (_) {
        // Mantém a mensagem padrão.
      }

      throw Exception(mensagem);
    }

    final dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! Map) {
      throw Exception('A API retornou uma resposta inválida.');
    }

    return Map<String, dynamic>.from(dados);
  }

  static String _formatarData(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }
}
