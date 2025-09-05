import 'package:flutter/material.dart';
import '../models/plant_data.dart';

class PlantDetailScreen extends StatelessWidget {
  final PlantData plantData;

  const PlantDetailScreen({super.key, required this.plantData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plantData.name),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem da planta
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
                ),
              ),
              child: plantData.imageUrl.isNotEmpty
                  ? Image.network(
                      plantData.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlantIcon(),
                    )
                  : _buildPlantIcon(),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e nome científico
                  Text(
                    plantData.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plantData.scientificName,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Descrição
                  _buildSectionWithColor(
                    'Descrição',
                    plantData.description,
                    Icons.info_outline,
                    Colors.orange,
                    Colors.black,
                  ),

                  // Exposição ao sol
                  _buildSectionWithColor(
                    'Exposição ao Sol',
                    plantData.sunExposure,
                    Icons.wb_sunny,
                    Colors.yellow[700]!,
                    Colors.black,
                  ),

                  // Frequência de rega
                  _buildSectionWithColor(
                    'Frequência de Rega',
                    '${plantData.wateringFrequency} vez(es) por dia',
                    Icons.water_drop,
                    Colors.blue,
                    Colors.black,
                  ),

                  // Tipo de solo
                  _buildSectionWithColor(
                    'Tipo de Solo',
                    plantData.soilType,
                    Icons.grass,
                    const Color(0xFF2E7D32), // Verde escuro para o ícone
                    Colors.black, // Texto preto para o título
                  ),

                  // Dificuldade
                  _buildSectionWithColor(
                    'Dificuldade de Cultivo',
                    plantData.difficulty,
                    Icons.psychology,
                    Colors.red,
                    Colors.black,
                  ),

                  // Cuidados especiais
                  _buildSectionWithColor(
                    'Cuidados Especiais',
                    plantData.specialCare,
                    Icons.favorite,
                    Colors.pink,
                    Colors.black,
                  ),

                  const SizedBox(height: 20),

                  // Botão de voltar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar ao Monitoramento'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantIcon() {
    return Center(
      child: Icon(
        Icons.local_florist,
        size: 120,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildSectionWithColor(
    String title,
    String content,
    IconData icon,
    Color iconColor,
    Color titleColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
