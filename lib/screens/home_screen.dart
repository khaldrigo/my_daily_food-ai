import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para a função de copiar
import '../models/food_item.dart';
import '../models/meal_response.dart';
import '../services/ollama_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<FoodItem> _mealList = [];
  final TextEditingController _foodCtrl = TextEditingController();
  final TextEditingController _gramsCtrl = TextEditingController();
  final OllamaApi _api = OllamaApi();

  MealResponse? _mealData;

  bool _useWeb = false;
  bool _isLoading = false;
  String _result = "";

  void _addItem() {
    if (_foodCtrl.text.isNotEmpty && _gramsCtrl.text.isNotEmpty) {
      setState(() {
        _mealList.add(
          FoodItem(name: _foodCtrl.text, grams: double.parse(_gramsCtrl.text)),
        );
        _foodCtrl.clear();
        _gramsCtrl.clear();
      });
    }
  }

  Future<void> _processar() async {
    setState(() {
      _isLoading = true;
      _result = "";
    });

    final String rawAiString = await _api.gerarInsight(_mealList, _useWeb);

    try {
      final jsonStart = rawAiString.indexOf('{');
      final jsonEnd = rawAiString.lastIndexOf('}') + 1;
      final cleanJson = rawAiString.substring(jsonStart, jsonEnd);

      final Map<String, dynamic> decoded = jsonDecode(cleanJson);

      setState(() {
        // Agora mapeamos diretamente os campos do novo MealResponse
        _mealData = MealResponse.fromJson(decoded);
        _isLoading = false;
      });
    } catch (e) {
      log("Erro de Parse: $e | String recebida: $rawAiString");
      setState(() {
        _result = "Erro na resposta da IA. Tente gerar novamente.";
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_mealData == null) return;

    final text =
        "Macros: ${_mealData!.kcal.toStringAsFixed(0)} kcal | "
        "P: ${_mealData!.proteina.toStringAsFixed(1)}g | "
        "C: ${_mealData!.carbo.toStringAsFixed(1)}g | "
        "G: ${_mealData!.gordura.toStringAsFixed(1)}g";

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Copiado para o Yazio!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Daily Food AI'), centerTitle: true),
      body: Column(
        children: [
          if (_mealData != null) _buildMacroTable(),
          if (_result.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_result, style: const TextStyle(color: Colors.red)),
            ),

          const Divider(),
          _buildInputSection(),
          _buildItemList(),
          _buildActionSection(),
        ],
      ),
    );
  }

  Widget _buildMacroTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.deepPurple.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total da Refeição",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: _copyToClipboard,
                tooltip: "Copiar para o Yazio",
              ),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(
              color: Colors.deepPurple.withValues(alpha: 0.3),
            ),
            children: [
              const TableRow(
                children: [
                  _TableHeader("Kcal"),
                  _TableHeader("Prot (g)"),
                  _TableHeader("Carb (g)"),
                  _TableHeader("Gord (g)"),
                ],
              ),
              TableRow(
                children: [
                  _TableCell(_mealData!.kcal.toStringAsFixed(0)),
                  _TableCell(_mealData!.proteina.toStringAsFixed(1)),
                  _TableCell(_mealData!.carbo.toStringAsFixed(1)),
                  _TableCell(_mealData!.gordura.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _foodCtrl,
              decoration: const InputDecoration(labelText: 'Alimento'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _gramsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'g'),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Colors.deepPurple,
              size: 32,
            ),
            onPressed: _addItem,
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _mealList.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.restaurant_menu),
          title: Text(_mealList[index].name),
          subtitle: Text("${_mealList[index].grams}g"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _mealList.removeAt(index)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("Pesquisa Web"),
            value: _useWeb,
            onChanged: (val) => setState(() => _useWeb = val),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: _mealList.isEmpty || _isLoading ? null : _processar,
            icon: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.auto_awesome),
            label: const Text('GERAR INSIGHT'),
          ),
        ],
      ),
    );
  }
}

// Widgets auxiliares para a tabela ficar limpa
class _TableHeader extends StatelessWidget {
  final String label;
  const _TableHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}

class _TableCell extends StatelessWidget {
  final String value;
  const _TableCell(this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(value, textAlign: TextAlign.center),
  );
}
