import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_info.dart';

class GeminiService {
  // We'll resolve API version and model dynamically using ListModels.
  static const String _apiHost = 'https://generativelanguage.googleapis.com';
  static const List<String> _apiVersions = ['v1', 'v1beta'];
  // Preference order for models; we will pick the first available from ListModels
  static const List<String> _preferredModels = <String>[
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
    'gemini-pro',
  ];
  static const String _cacheKeyPrefix = 'plant_info_v2_';

  // Cached resolution to avoid repeated network calls
  static String? _resolvedApiVersion;
  static String? _resolvedModelId;

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

      // Ensure we have a supported API version and model before calling generateContent
      await _ensureModelAndVersionResolved();

      final prompt = _buildPrompt(plantName);

      final endpoint =
          '$_apiHost/${_resolvedApiVersion!}/models/${_resolvedModelId!}:generateContent?key=$_apiKey';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'role': 'user',
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
          // Concatena todos os parts de texto para garantir que nada se perca
          final parts =
              (data['candidates'][0]['content']['parts'] as List?) ?? const [];
          String content = '';
          for (final p in parts) {
            if (p is Map && p['text'] is String) {
              content += (p['text'] as String);
              if (!content.endsWith('\n')) content += '\n';
            }
          }
          if (content.trim().isEmpty &&
              data['candidates'][0]['content'] is Map) {
            // Fallback: tenta um possível campo 'text' direto (variações de API)
            final maybeText = data['candidates'][0]['content']['text'];
            if (maybeText is String) content = maybeText;
          }

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
          debugPrint('Endpoint: $endpoint');
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

  // Ensure we have a working API version and model by calling ListModels and matching preferences
  static Future<void> _ensureModelAndVersionResolved() async {
    if (_resolvedApiVersion != null && _resolvedModelId != null) return;

    // Try versions in order: v1, then v1beta
    for (final version in _apiVersions) {
      final models = await _listModels(version);
      if (models == null || models.isEmpty) continue;

      // Build a set of available model ids for fast lookup
      final available = models.toSet();
      // Try preferred models first
      for (final preferred in _preferredModels) {
        if (available.contains(preferred) ||
            available.contains('$preferred-latest')) {
          _resolvedApiVersion = version;
          _resolvedModelId = available.contains(preferred)
              ? preferred
              : '$preferred-latest';
          if (kDebugMode) {
            debugPrint(
              'Gemini model resolved: version=$_resolvedApiVersion, model=$_resolvedModelId',
            );
          }
          return;
        }
      }

      // Fallback: pick the first model containing 'gemini'
      final fallback = models.firstWhere(
        (m) => m.startsWith('gemini'),
        orElse: () => '',
      );
      if (fallback.isNotEmpty) {
        _resolvedApiVersion = version;
        _resolvedModelId = fallback;
        if (kDebugMode) {
          debugPrint(
            'Gemini model fallback: version=$_resolvedApiVersion, model=$_resolvedModelId',
          );
        }
        return;
      }
    }

    // If still unresolved, default to v1 with gemini-pro (may still error but gives clear logs)
    _resolvedApiVersion = 'v1';
    _resolvedModelId = 'gemini-pro';
    if (kDebugMode) {
      debugPrint(
        'Gemini model unresolved; defaulting to version=v1, model=gemini-pro',
      );
    }
  }

  // Call ListModels for a given version; returns list of model ids supported for generateContent
  static Future<List<String>?> _listModels(String version) async {
    try {
      final uri = Uri.parse(
        '$_apiHost/$version/models?key=${dotenv.env['GEMINIAI_API_KEY'] ?? ''}',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            'ListModels failed for $version: ${res.statusCode} - ${res.body}',
          );
        }
        return null;
      }
      final body = json.decode(res.body) as Map<String, dynamic>;
      final models =
          (body['models'] as List<dynamic>?)
              ?.map((e) => (e as Map<String, dynamic>)['name'] as String)
              .toList() ??
          <String>[];

      // names are like: models/gemini-1.5-flash-latest — extract the id after last '/'
      final ids = <String>[];
      for (final name in models) {
        final idx = name.lastIndexOf('/');
        final id = idx >= 0 ? name.substring(idx + 1) : name;
        ids.add(id);
      }
      return ids;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro em ListModels($version): $e');
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

      // Tenta decodificar JSON de forma resiliente
      Map<String, dynamic>? jsonData = _tryDecodeLooseJson(jsonString);

      if (jsonData == null) {
        // Como fallback, retorna ao menos a descrição completa na ausência de JSON
        return PlantInfo(
          nome: plantName,
          descricao: jsonString,
          exposicaoSol: 'Informação não disponível',
          frequenciaRega: 'Informação não disponível',
          tipoSolo: 'Informação não disponível',
          dificuldadeCultivo: 'Informação não disponível',
          cuidadosEspeciais: 'Informação não disponível',
        );
      }

      // Normaliza chaves e aceita variações (pt/en, com/sem acentos)
      final normalized = <String, dynamic>{};
      jsonData.forEach((k, v) {
        normalized[_normalizeKey(k)] = v;
      });

      String pick(
        List<String> keys, {
        String fallback = 'Informação não disponível',
      }) {
        for (final key in keys) {
          final nk = _normalizeKey(key);
          if (normalized.containsKey(nk)) {
            final val = normalized[nk];
            if (val is String && val.trim().isNotEmpty) return val.trim();
          }
        }
        return fallback;
      }

      final nome = pick([
        'nome',
        'name',
        'plantName',
        'nomePlanta',
      ], fallback: plantName);
      final descricao = pick([
        'descricao',
        'descrição',
        'description',
        'sobre',
      ]);
      final exposicaoSol = pick([
        'exposicaoSol',
        'exposição ao sol',
        'exposicao_ao_sol',
        'sunExposure',
        'light',
        'exposure',
      ]);
      final frequenciaRega = pick([
        'frequenciaRega',
        'frequência de rega',
        'frequencia_de_rega',
        'wateringFrequency',
        'irrigationFrequency',
        'rega',
      ]);
      final tipoSolo = pick([
        'tipoSolo',
        'tipo de solo',
        'tipo_de_solo',
        'soilType',
        'soil',
      ]);
      final dificuldadeCultivo = pick([
        'dificuldadeCultivo',
        'dificuldade de cultivo',
        'cultivationDifficulty',
        'difficulty',
      ]);
      final cuidadosEspeciais = pick([
        'cuidadosEspeciais',
        'cuidados especiais',
        'specialCare',
        'care',
      ]);

      return PlantInfo(
        nome: nome,
        descricao: descricao,
        exposicaoSol: exposicaoSol,
        frequenciaRega: frequenciaRega,
        tipoSolo: tipoSolo,
        dificuldadeCultivo: dificuldadeCultivo,
        cuidadosEspeciais: cuidadosEspeciais,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao fazer parse da resposta Gemini: $e');
        debugPrint('Conteúdo recebido: $content');
      }
      return null;
    }
  }

  // Tenta decodificar JSON com sanitizações comuns (aspas, vírgulas finais, chaves)
  Map<String, dynamic>? _tryDecodeLooseJson(String s) {
    // 1) Tentativa direta
    try {
      final obj = json.decode(s);
      if (obj is Map<String, dynamic>) return obj;
      if (obj is List && obj.isNotEmpty && obj.first is Map<String, dynamic>) {
        return obj.first as Map<String, dynamic>;
      }
    } catch (_) {}

    // 2) Extrai primeiro bloco entre { ... }
    try {
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start >= 0 && end > start) {
        var t = s.substring(start, end + 1);
        // Normaliza aspas “ ” ‘ ’
        t = t
            .replaceAll('\u201c', '"')
            .replaceAll('\u201d', '"')
            .replaceAll('\u2019', "'")
            .replaceAll('\u2018', "'")
            .replaceAll('“', '"')
            .replaceAll('”', '"')
            .replaceAll('’', "'")
            .replaceAll('‘', "'");
        // Remove vírgulas finais antes de } ]
        t = t.replaceAll(RegExp(r",\s*([}\]])"), r"$1");
        // Troca chaves/valores com aspas simples por duplas (heurística)
        t = t.replaceAllMapped(RegExp(r"'([^']+)'\s*:"), (m) => '"${m[1]}":');
        t = t.replaceAllMapped(RegExp(r":\s*'([^']*)'"), (m) => ': "${m[1]}"');

        final obj = json.decode(t);
        if (obj is Map<String, dynamic>) return obj;
        if (obj is List &&
            obj.isNotEmpty &&
            obj.first is Map<String, dynamic>) {
          return obj.first as Map<String, dynamic>;
        }
      }
    } catch (_) {}

    return null;
  }

  // Normaliza chaves: minúsculas, sem acentos, sem espaços/underscore/hífens
  String _normalizeKey(String key) {
    String s = key.toLowerCase();
    const map = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp(r'[\s_\-]'), '');
    return s;
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
