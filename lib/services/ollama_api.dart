import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class OllamaApi {
  final String _baseUrl = "http://192.168.15.28:11434/api/generate";

  /// 1. MÉTODO DE PESQUISA (RAG - Retrieval)
  /// Simula uma busca simples. Para resultados reais, você pode usar a API do DuckDuckGo.
  Future<String> _searchWeb(String query) async {
    log('Pesquisando na web por: $query');
    try {
      // Usando a API gratuita do DuckDuckGo para buscar definições/dados rápidos
      final url = Uri.parse(
        "https://api.duckduckgo.com/?q=$query&format=json&no_html=1",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Retorna o resumo (Abstract) ou uma mensagem padrão
        return data['AbstractText']?.isNotEmpty == true
            ? "Dados Web: ${data['AbstractText']}"
            : "Sem resultados específicos na web para $query.";
      }
      return "Erro ao acessar base web.";
    } catch (e) {
      return "Busca offline: Não foi possível obter dados externos.";
    }
  }

  /// 2. MÉTODO PRINCIPAL (RAG - Generation)
  Future<String> gerarInsight(List<FoodItem> items, bool useWeb) async {
    log('Iniciando GerarInsight...');

    try {
      // A. Carrega as regras do arquivo TXT (Contexto Local)
      String contextRules = await rootBundle.loadString('assets/ai_rules.txt');

      // B. Se o Toggle estiver ativo, busca na Web (Contexto Externo)
      String webContext = "";
      if (useWeb && items.isNotEmpty) {
        // Busca apenas o primeiro item ou uma combinação para ganhar tempo
        webContext = await _searchWeb(items.first.name);
      }

      // C. Montagem do Prompt Aumentado (O "Pulo do Gato" do RAG)
      final String listaItens = items
          .map((e) => "${e.grams}g de ${e.name}")
          .join(", ");

      final String finalPrompt =
          """
      $contextRules
      
      DADOS EXTERNOS RECENTES:
      $webContext
      
      TAREFA ATUAL:
      Analise nutricionalmente estes itens: $listaItens.
      Retorne o JSON com o total e o resumo por item.
      """;

      // D. Envio para o Manjaro
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "model": "qwen2.5:1.5b",
              "prompt": finalPrompt,
              "stream": false,
              "format": "json", // Garante que o Qwen use o modo JSON
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final outerJson = jsonDecode(response.body);
        final String aiResponse = outerJson['response'] ?? '{}';
        log('resposta raw: $aiResponse');
        log("Resposta da IA recebida com sucesso.");
        return aiResponse;
      } else {
        return "Erro no Manjaro: ${response.statusCode}";
      }
    } catch (e) {
      log("Erro crítico no processo: $e");
      return "Erro: $e";
    }
  }
}
