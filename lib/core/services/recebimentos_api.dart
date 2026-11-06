import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecebimentosApi {
  static const String _baseUrl =
      'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  static Future<Map<String, dynamic>> _sessao() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final idEmpresa = prefs.getInt('idEmpresa');
    final idUsuario = prefs.getInt('idUsuario');

    if (token == null || token.isEmpty) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    if (idEmpresa == null || idUsuario == null) {
      throw Exception('Não foi possível identificar sua empresa ou usuário.');
    }

    return {
      'token': token,
      'idEmpresa': idEmpresa,
      'idUsuario': idUsuario,
    };
  }

  static Future<List<Map<String, dynamic>>> listarPorConta({
    required int idContaReceber,
  }) async {
    final sessao = await _sessao();

    final idEmpresa = sessao['idEmpresa'] as int;
    final token = sessao['token'] as String;

    final uri = Uri.parse(
      '$_baseUrl/api/recebimentos/conta/$idContaReceber',
    ).replace(
      queryParameters: {
        'idEmpresa': idEmpresa.toString(),
      },
    );

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
      throw Exception('Você não tem permissão para consultar os recebimentos.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível consultar os recebimentos '
        '(HTTP ${response.statusCode}).',
      );
    }

    final dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! List) {
      throw Exception('A API retornou um histórico inválido.');
    }

    return dados
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<int> criar({
    required int idContaReceber,
    required int idCategoria,
    int? idCentroCusto,
    required double valorRecebido,
    required DateTime dataRecebimento,
  }) async {
    final sessao = await _sessao();

    final idEmpresa = sessao['idEmpresa'] as int;
    final idUsuario = sessao['idUsuario'] as int;
    final token = sessao['token'] as String;

    final uri = Uri.parse('$_baseUrl/api/recebimentos');

    final body = <String, dynamic>{
      'idEmpresa': idEmpresa,
      'idContaReceber': idContaReceber,
      'idCategoria': idCategoria,
      'idCentroCusto': idCentroCusto,
      'idUsuario': idUsuario,
      'valorRecebido': valorRecebido,
      'dataRecebimento': _formatarData(dataRecebimento),
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

    final dados = _decodificarResposta(response);

    if (response.statusCode == 401) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    if (response.statusCode == 403) {
      throw Exception('Você não tem permissão para registrar este recebimento.');
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      final mensagem = dados is Map && dados['mensagem'] != null
          ? dados['mensagem'].toString()
          : 'Não foi possível registrar o recebimento '
              '(HTTP ${response.statusCode}).';

      throw Exception(mensagem);
    }

    if (dados is! Map || dados['idRecebimento'] == null) {
      throw Exception('A API não retornou o ID do recebimento.');
    }

    return (dados['idRecebimento'] as num).toInt();
  }

  static dynamic _decodificarResposta(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static String _formatarData(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }
}