import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MovieApiProvider {
  String _apiKey = '';

  MovieApiProvider();

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('movie_api_token') ?? '';
  }

  final String _baseUrl = "https://movies-api-production-025d.up.railway.app";

  Future<List<Map<String, dynamic>>> getDirectors() async {
    // Garante que a API key seja carregada antes de fazer a requisição
    await _loadApiKey();

    debugPrint('API Key sendo usada: $_apiKey');

    if (_apiKey.isEmpty) {
      throw Exception(
        'API Key não encontrada. Verifique se está salva no SharedPreferences.',
      );
    }

    final response = await http.get(
      Uri.parse("$_baseUrl/directors"),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar diretores: ${response.statusCode}');
    }

    final responseData = jsonDecode(response.body);
    
    final directors = responseData['data'];
    return List<Map<String, dynamic>>.from(directors);
  }
}
