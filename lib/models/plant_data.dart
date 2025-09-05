class PlantData {
  final String name;
  final String scientificName;
  final String imageUrl;
  final String sunExposure;
  final int wateringFrequency; // vezes por dia
  final String specialCare;
  final String description;
  final String soilType;
  final String difficulty;

  PlantData({
    required this.name,
    required this.scientificName,
    required this.imageUrl,
    required this.sunExposure,
    required this.wateringFrequency,
    required this.specialCare,
    required this.description,
    required this.soilType,
    required this.difficulty,
  });

  factory PlantData.fromJson(Map<String, dynamic> json) {
    return PlantData(
      name: json['name'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      sunExposure: json['sun_exposure'] ?? '',
      wateringFrequency: json['watering_frequency'] ?? 1,
      specialCare: json['special_care'] ?? '',
      description: json['description'] ?? '',
      soilType: json['soil_type'] ?? '',
      difficulty: json['difficulty'] ?? '',
    );
  }

  // Dados padrão do girassol para quando não houver API disponível
  static PlantData get defaultSunflower => PlantData(
    name: 'Girassol',
    scientificName: 'Helianthus annuus',
    imageUrl:
        'https://images.unsplash.com/photo-1597848212624-379933cf2193?w=500',
    sunExposure: 'Sol pleno (6-8 horas diárias)',
    wateringFrequency: 2,
    specialCare:
        'Girar o vaso ocasionalmente para crescimento uniforme. Suporte para plantas altas.',
    description:
        'O girassol é uma planta anual conhecida por suas grandes flores amarelas que seguem o movimento do sol.',
    soilType: 'Solo bem drenado, rico em matéria orgânica',
    difficulty: 'Fácil',
  );
}
