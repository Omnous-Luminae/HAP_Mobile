import '../config/api_config.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart';

class FavorisService {
 static Future<List<Map<String, dynamic>>> getFavoris({String? token}) async {
  final tok = await ApiService.getToken();
  print('URL FAVORIS: ${ApiConfig.favoris}');
  
  // Appel direct http pour voir la réponse brute
  final uri = Uri.parse(ApiConfig.favoris);
  final response = await http.get(uri, headers: {
    'Authorization': 'Bearer $tok',
    'Content-Type': 'application/json',
  });
  print('STATUS: ${response.statusCode}');
  print('BODY: ${response.body}');
  
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(data['data'] as List);
}

  static Future<void> retirerFavori({required int idBiens, String? token}) async {
    // ApiService ne supporte pas DELETE — on passe par post sur un endpoint dédié
    // ou on utilise http directement avec le token de ApiService
    final tok = await ApiService.getToken();
    final request = http.Request('DELETE', Uri.parse(ApiConfig.favoris));
    request.headers['Authorization'] = 'Bearer $tok';
    request.headers['Content-Type']  = 'application/json';
    request.body = jsonEncode({'id_biens': idBiens});
    final streamed = await request.send().timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur lors de la suppression.');
    }
  }
}