import 'dart:convert';
import 'package:http/http.dart' as http;

class ContasPagarApi {
  static const String baseUrl = 'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  static Future<List<Map<String, dynamic>>> listar() async {
    final uri = Uri.parse('$baseUrl/api/contas-pagar');

    final response = await http
        .get(
          uri,
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao carregar contas. Código HTTP: ${response.statusCode}',
      );
    }

    final dynamic dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! List) {
      throw Exception('A API retornou um formato inesperado.');
    }

    return dados
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>> listarCategorias() async {
    final uri = Uri.parse('$baseUrl/api/categorias');

    final response = await http
        .get(
          uri,
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao carregar categorias. Código HTTP: ${response.statusCode}',
      );
    }

    final dynamic dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! List) {
      throw Exception('A API de categorias retornou um formato inesperado.');
    }

    return dados
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> criar({
    required int idEmpresa,
    required int idCategoria,
    required String descricao,
    required double valorOriginal,
    required DateTime dataEmissao,
    required DateTime dataVencimento,
    int? idCentroCusto,
  }) async {
    final uri = Uri.parse('$baseUrl/api/contas-pagar');

    final body = <String, dynamic>{
      'idEmpresa': idEmpresa,
      'idCategoria': idCategoria,
      'tipoCategoria': 'DESPESA',
      'descricao': descricao,
      'valorOriginal': valorOriginal,
      'dataEmissao': _formatarDataApi(dataEmissao),
      'dataVencimento': _formatarDataApi(dataVencimento),
    };

    if (idCentroCusto != null) {
      body['idCentroCusto'] = idCentroCusto;
    }

    final response = await http
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final detalhe = response.body.isNotEmpty
          ? utf8.decode(response.bodyBytes)
          : 'Sem detalhes adicionais.';

      throw Exception(
        'Erro ao salvar a conta. HTTP ${response.statusCode}: $detalhe',
      );
    }

    if (response.body.trim().isEmpty) {
      return body;
    }

    final dynamic dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is Map<String, dynamic>) {
      return dados;
    }

    return body;
  }

  static String _formatarDataApi(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }
}