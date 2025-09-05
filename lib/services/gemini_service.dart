import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_info.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  static const String _cacheKeyPrefix = 'plant_info_';

  String get _apiKey => dotenv.env['GEMINIAI_API_KEY'] ?? '';

  /// Busca informações da planta usando Google Gemini com cache
  Future<PlantInfo?> getPlantInfo(String plantName) async {
    try {
      // Verifica se já existe no cache
      final cachedInfo = await _getCachedPlantInfo(plantName);
      if (cachedInfo != null) {
        if (kDebugMode) {
          debugPrint('Dados encontrados no cache para: $plantName');
        }
        return cachedInfo;
      }

      if (_apiKey.isEmpty) {
        if (kDebugMode) {
          debugPrint('API Key do Gemini não encontrada');
        }
        return null;
      }

      final prompt = _buildPrompt(plantName);

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 800,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];

          final plantInfo = _parseGeminiResponse(content, plantName);

          if (plantInfo != null) {
            // Salva no cache
            await _cachePlantInfo(plantName, plantInfo);
          }

          return plantInfo;
        } else {
          if (kDebugMode) {
            debugPrint('Nenhuma resposta válida do Gemini');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Erro na API Gemini: ${response.statusCode} - ${response.body}',
          );
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar informações da planta: $e');
      }
      return null;
    }
  }

  String _buildPrompt(String plantName) {
    return '''
Por favor, forneça informações detalhadas sobre a planta "$plantName" no seguinte formato JSON EXATO:

{
  "nome": "Nome da planta",
  "descricao": "Descrição detalhada da planta",
  "exposicaoSol": "Necessidades de exposição solar",
  "frequenciaRega": "Frequência de rega recomendada",
  "tipoSolo": "Tipo de solo ideal",
  "dificuldadeCultivo": "Nível de dificuldade (Fácil/Moderado/Difícil)",
  "cuidadosEspeciais": "Cuidados especiais necessários"
}

IMPORTANTE: Responda APENAS com o JSON válido, sem texto adicional antes ou depois. Não use markdown ou código formatado.
''';
  }

  PlantInfo? _parseGeminiResponse(String content, String plantName) {
    try {
      // Remove possíveis caracteres extras e extrai apenas o JSON
      String jsonString = content.trim();

      // Remove markdown code blocks se existirem
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7);
      }
      if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3);
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }

      jsonString = jsonString.trim();

      final Map<String, dynamic> jsonData = json.decode(jsonString);

      return PlantInfo(
        nome: jsonData['nome'] ?? plantName,
        descricao: jsonData['descricao'] ?? 'Informação não disponível',
        exposicaoSol: jsonData['exposicaoSol'] ?? 'Informação não disponível',
        frequenciaRega:
            jsonData['frequenciaRega'] ?? 'Informação não disponível',
        tipoSolo: jsonData['tipoSolo'] ?? 'Informação não disponível',
        dificuldadeCultivo:
            jsonData['dificuldadeCultivo'] ?? 'Informação não disponível',
        cuidadosEspeciais:
            jsonData['cuidadosEspeciais'] ?? 'Informação não disponível',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao fazer parse da resposta Gemini: $e');
        debugPrint('Conteúdo recebido: $content');
      }
      return null;
    }
  }

  /// Busca informações no cache
  Future<PlantInfo?> _getCachedPlantInfo(String plantName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKeyPrefix + plantName.toLowerCase();
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null) {
        final Map<String, dynamic> jsonData = json.decode(cachedJson);
        return PlantInfo.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar cache: $e');
      }
      return null;
    }
  }

  /// Salva informações no cache
  Future<void> _cachePlantInfo(String plantName, PlantInfo plantInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cacheKeyPrefix + plantName.toLowerCase();
      final jsonString = json.encode(plantInfo.toJson());

      await prefs.setString(cacheKey, jsonString);

      if (kDebugMode) {
        debugPrint('Informações salvas no cache para: $plantName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao salvar no cache: $e');
      }
    }
  }

  /// Limpa o cache de plantas
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }

      if (kDebugMode) {
        debugPrint('Cache de plantas limpo');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao limpar cache: $e');
      }
    }
  }
}
