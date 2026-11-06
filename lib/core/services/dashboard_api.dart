import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardApi {
  static const String baseUrl =
      'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  // Obtém o token salvo durante o login.
  static Future<String> _obterToken() async {
    final preferencias = await SharedPreferences.getInstance();

    final token = preferencias.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'Sua sessão não foi encontrada. Faça login novamente.',
      );
    }

    return token;
  }

  // Faz uma requisição autenticada à API.
  static Future<dynamic> _get(String endpoint) async {
    final token = await _obterToken();

    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) {
      throw Exception(
        'Sua sessão expirou ou o token não é válido. Faça login novamente.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Você não tem permissão para acessar esses dados.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao consultar o dashboard (HTTP ${response.statusCode}).',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('A API retornou uma resposta vazia.');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  // Resumo financeiro: saldo, receitas e despesas.
  static Future<Map<String, dynamic>> obterResumo() async {
    final dados = await _get('/api/dashboard');

    if (dados is! Map) {
      throw Exception('Formato inválido no resumo financeiro.');
    }

    return Map<String, dynamic>.from(dados);
  }

  // Despesas agrupadas por categoria.
  static Future<List<Map<String, dynamic>>>
      obterDespesasPorCategoria() async {
    final dados = await _get(
      '/api/dashboard/despesas-por-categoria',
    );

    if (dados is! List) {
      throw Exception('Formato inválido nas despesas por categoria.');
    }

    return dados
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Últimas dez movimentações.
  static Future<List<Map<String, dynamic>>>
      obterMovimentacoesRecentes() async {
    final dados = await _get(
      '/api/dashboard/movimentacoes-recentes',
    );

    if (dados is! List) {
      throw Exception('Formato inválido nas movimentações recentes.');
    }

    return dados
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Fluxo de caixa por data.
  static Future<List<Map<String, dynamic>>> obterFluxoDeCaixa() async {
    final dados = await _get('/api/dashboard/fluxo-de-caixa');

    if (dados is! List) {
      throw Exception('Formato inválido no fluxo de caixa.');
    }

    return dados
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}