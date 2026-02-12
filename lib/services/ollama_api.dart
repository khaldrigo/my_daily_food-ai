import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class OllamaApi {
  // O IP do seu Manjaro
  final String _baseUrl = "http://192.168.15.28:11434/api/generate";

  Future<void> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: jsonEncode({
          "model": "qwen2.5:1.5b",
          "prompt": "Olá, você está ouvindo?",
          "stream": false
        }),
      );
      log("Resposta do Manjaro: ${response.body}");
    } catch (e) {
      log("Erro ao conectar: $e");
    }
  }
}