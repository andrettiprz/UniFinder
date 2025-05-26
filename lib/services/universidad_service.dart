import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/universidad.dart';

class UniversidadService {
  static const String _baseUrl =
      'https://gist.githubusercontent.com/andrettiprz/e983726f070f9a6e92c0a3254e306dae/raw/c14ecd2016f460c6e7a78afc1061eb8a92b372e1/universidades_limpias.json';

  Future<List<Universidad>> getUniversidades() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Universidad.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load universities');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 