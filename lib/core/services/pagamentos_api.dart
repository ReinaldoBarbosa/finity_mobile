import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PagamentosApi {
  static const String baseUrl =
      'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  static Future<Map<String, dynamic>> _sessao() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final idEmpresa = prefs.getInt('idEmpresa');
    final idUsuario = prefs.getInt('idUsuario');

    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Entre novamente no aplicativo.');
    }

    if (idEmpresa == null || idEmpresa <= 0) {
      throw Exception('Não foi possível identificar a empresa da sessão.');
    }

    if (idUsuario == null || idUsuario <= 0) {
      throw Exception('Não foi possível identificar o usuário da sessão.');
    }

    return {
      'token': token,
      'idEmpresa': idEmpresa,
      'idUsuario': idUsuario,
    };
  }

  static Future<List<Map<String, dynamic>>> listarPorConta({
    required int idContaPagar,
  }) async {
    final sessao = await _sessao();

    final uri = Uri.parse(
      '$baseUrl/api/pagamentos/conta/$idContaPagar'
      '?idEmpresa=${sessao['idEmpresa']}',
    );

    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${sessao['token']}',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        _mensagemErro(response, 'Não foi possível carregar os pagamentos.'),
      );
    }

    final dynamic dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! List) {
      throw Exception('A API retornou um histórico em formato inesperado.');
    }

    return dados
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  static Future<int?> criar({
    required int idContaPagar,
    required int idCategoria,
    int? idCentroCusto,
    required double valorPago,
    required DateTime dataPagamento,
  }) async {
    final sessao = await _sessao();

    final body = <String, dynamic>{
      'idEmpresa': sessao['idEmpresa'],
      'idContaPagar': idContaPagar,
      'idCategoria': idCategoria,
      'idUsuario': sessao['idUsuario'],
      'valorPago': valorPago,
      'dataPagamento': _formatarData(dataPagamento),
    };

    if (idCentroCusto != null) {
      body['idCentroCusto'] = idCentroCusto;
    }

    final uri = Uri.parse('$baseUrl/api/pagamentos');

    final response = await http
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${sessao['token']}',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        _mensagemErro(response, 'Não foi possível registrar o pagamento.'),
      );
    }

    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final dynamic dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is Map && dados['id'] is num) {
      return (dados['id'] as num).toInt();
    }

    return null;
  }

  static String _formatarData(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  static String _mensagemErro(
    http.Response response,
    String mensagemPadrao,
  ) {
    try {
      final dynamic dados = jsonDecode(utf8.decode(response.bodyBytes));

      if (dados is Map) {
        final mensagem = dados['mensagem'] ?? dados['title'];

        if (mensagem != null && mensagem.toString().trim().isNotEmpty) {
          return mensagem.toString();
        }
      }
    } catch (_) {
      // Mantém a mensagem padrão se a resposta não for JSON.
    }

    if (response.statusCode == 401) {
      return 'Sua sessão expirou. Entre novamente no aplicativo.';
    }

    if (response.statusCode == 403) {
      return 'Você não tem permissão para realizar esta operação.';
    }

    return '$mensagemPadrao Código HTTP: ${response.statusCode}.';
  }
}