import 'package:flutter/material.dart';
import '../models/plant_info.dart';
import '../services/gemini_service.dart';

class PlantSearchScreen extends StatefulWidget {
  const PlantSearchScreen({super.key});

  @override
  State<PlantSearchScreen> createState() => _PlantSearchScreenState();
}

class _PlantSearchScreenState extends State<PlantSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  PlantInfo? _currentPlantInfo;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlant() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite o nome de uma planta';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPlantInfo = null;
    });

    try {
      final plantInfo = await _geminiService.getPlantInfo(
        _searchController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        if (plantInfo != null) {
          _currentPlantInfo = plantInfo;
        } else {
          _errorMessage =
              'Não foi possível encontrar informações sobre esta planta';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao buscar informações: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Planta'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Nome da planta',
                hintText: 'Ex: Rosa, Girassol, Lavanda...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E7D32),
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _searchPlant(),
            ),

            const SizedBox(height: 16),

            // Botão de busca
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchPlant,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Buscando...' : 'Buscar Planta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Resultado
            Expanded(child: _buildResult()),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_currentPlantInfo == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Digite o nome de uma planta para buscar informações',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome da planta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPlantInfo!.nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Informações detalhadas
          _buildInfoSection(
            'Descrição',
            _currentPlantInfo!.descricao,
            Icons.info_outline,
          ),
          _buildInfoSection(
            'Exposição ao Sol',
            _currentPlantInfo!.exposicaoSol,
            Icons.wb_sunny,
          ),
          _buildInfoSection(
            'Frequência de Rega',
            _currentPlantInfo!.frequenciaRega,
            Icons.water_drop,
          ),
          _buildInfoSection(
            'Tipo de Solo',
            _currentPlantInfo!.tipoSolo,
            Icons.grass,
          ),
          _buildInfoSection(
            'Dificuldade de Cultivo',
            _currentPlantInfo!.dificuldadeCultivo,
            Icons.psychology,
          ),
          _buildInfoSection(
            'Cuidados Especiais',
            _currentPlantInfo!.cuidadosEspeciais,
            Icons.favorite,
          ),

          const SizedBox(height: 20),

          // Botão para usar esta planta
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, _currentPlantInfo);
              },
              icon: const Icon(Icons.check),
              label: const Text('Usar Esta Planta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    // Define cor do ícone baseado no tipo
    Color iconColor = const Color(0xFF2E7D32); // Verde escuro padrão
    if (icon == Icons.grass) {
      iconColor = const Color(0xFF2E7D32); // Verde escuro para grama
    } else if (icon == Icons.wb_sunny) {
      iconColor = Colors.yellow[700]!;
    } else if (icon == Icons.water_drop) {
      iconColor = Colors.blue;
    } else if (icon == Icons.psychology) {
      iconColor = Colors.red;
    } else if (icon == Icons.favorite) {
      iconColor = Colors.pink;
    } else if (icon == Icons.info_outline) {
      iconColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Títulos em preto
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
