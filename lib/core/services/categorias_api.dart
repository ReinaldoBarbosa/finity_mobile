import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CategoriasApi {
  static const String _baseUrl =
      'https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net';

  static Future<List<Map<String, dynamic>>> listarReceitas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final idEmpresa = prefs.getInt('idEmpresa');

    if (token == null || token.isEmpty) {
      throw Exception('Sua sessão expirou. Faça login novamente.');
    }

    if (idEmpresa == null) {
      throw Exception('Não foi possível identificar sua empresa.');
    }

    final uri = Uri.parse('$_baseUrl/api/categorias');

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

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível carregar as categorias '
        '(HTTP ${response.statusCode}).',
      );
    }

    final dados = jsonDecode(utf8.decode(response.bodyBytes));

    if (dados is! List) {
      throw Exception('A API retornou uma lista de categorias inválida.');
    }

    return dados
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((categoria) {
          final categoriaEmpresa =
              int.tryParse(categoria['idEmpresa'].toString());

          final tipo =
              categoria['tipo']?.toString().toUpperCase().trim();

          final ativa = categoria['ativo'] == true;

          return categoriaEmpresa == idEmpresa &&
              tipo == 'RECEITA' &&
              ativa;
        })
        .toList();
  }
}
