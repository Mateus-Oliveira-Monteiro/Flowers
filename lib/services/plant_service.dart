import 'package:flutter/foundation.dart';
import '../models/plant_data.dart';

class PlantService {
  /// Busca informações da planta (girassol por padrão)
  Future<PlantData> getPlantData({String plantName = 'sunflower'}) async {
    try {
      // Para implementação futura com API real
      // Atualmente retorna dados estáticos

      return PlantData.defaultSunflower;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar dados da planta: $e');
      }
      // Retorna dados padrão em caso de erro
      return PlantData.defaultSunflower;
    }
  }

  /// Simula busca de múltiplas plantas
  Future<List<PlantData>> getAvailablePlants() async {
    // Dados estáticos de algumas plantas para demonstração
    return [
      PlantData.defaultSunflower,
      PlantData(
        name: 'Rosa',
        scientificName: 'Rosa spp.',
        imageUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=500',
        sunExposure: 'Sol pleno (6+ horas diárias)',
        wateringFrequency: 1,
        specialCare:
            'Poda regular, fertilização mensal, proteção contra pragas.',
        description: 'Flores clássicas conhecidas por sua beleza e fragrância.',
        soilType: 'Solo bem drenado, rico em nutrientes',
        difficulty: 'Moderada',
      ),
      PlantData(
        name: 'Lavanda',
        scientificName: 'Lavandula angustifolia',
        imageUrl:
            'https://images.unsplash.com/photo-1571042195171-d37705263ec3?w=500',
        sunExposure: 'Sol pleno (6+ horas diárias)',
        wateringFrequency: 1,
        specialCare: 'Poda após floração, evitar excesso de água.',
        description: 'Planta aromática com propriedades relaxantes.',
        soilType: 'Solo bem drenado, levemente alcalino',
        difficulty: 'Fácil',
      ),
    ];
  }
}
