import 'package:flutter/material.dart';
import '../models/plant_data.dart';
import '../models/plant_info.dart';
import '../screens/plant_detail_screen.dart';
import '../screens/plant_search_screen.dart';

class PlantCard extends StatefulWidget {
  final PlantData? plantData;
  final PlantInfo? plantInfo;
  final double size;
  final Function(PlantInfo)? onPlantSelected;

  const PlantCard({
    super.key,
    this.plantData,
    this.plantInfo,
    this.size = 250.0,
    this.onPlantSelected,
  });

  @override
  State<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<PlantCard> {
  PlantInfo? _selectedPlantInfo;

  @override
  void initState() {
    super.initState();
    _selectedPlantInfo = widget.plantInfo;
  }

  void _navigateToSearch() async {
    final result = await Navigator.push<PlantInfo>(
      context,
      MaterialPageRoute(builder: (context) => const PlantSearchScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedPlantInfo = result;
      });
      widget.onPlantSelected?.call(result);
    }
  }

  void _navigateToDetails() {
    if (_selectedPlantInfo != null) {
      // Converter PlantInfo para PlantData para compatibilidade
      final plantData = PlantData(
        name: _selectedPlantInfo!.nome,
        scientificName: _selectedPlantInfo!.nome,
        imageUrl: '',
        sunExposure: _selectedPlantInfo!.exposicaoSol,
        wateringFrequency: 1,
        specialCare: _selectedPlantInfo!.cuidadosEspeciais,
        description: _selectedPlantInfo!.descricao,
        soilType: _selectedPlantInfo!.tipoSolo,
        difficulty: _selectedPlantInfo!.dificuldadeCultivo,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantDetailScreen(plantData: plantData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _selectedPlantInfo?.nome ?? widget.plantData?.name ?? '';
    final isPlantSelected = displayName.isNotEmpty;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone da planta
            Container(
              width: widget.size * 0.25,
              height: widget.size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_florist,
                size: widget.size * 0.15,
                color: const Color(0xFF2E7D32),
              ),
            ),

            SizedBox(height: widget.size * 0.05),

            // Nome da planta ou mensagem
            if (isPlantSelected)
              Text(
                displayName,
                style: TextStyle(
                  fontSize: widget.size * 0.07,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Cor preta para os nomes das plantas
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                'Escolha sua planta',
                style: TextStyle(
                  fontSize: widget.size * 0.06,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

            SizedBox(height: widget.size * 0.08),

            // Botão buscar planta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToSearch,
                icon: Icon(Icons.search, size: widget.size * 0.06),
                label: Text(
                  'Buscar Planta',
                  style: TextStyle(
                    fontSize: widget.size * 0.05,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: widget.size * 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_selectedPlantInfo != null) ...[
              SizedBox(height: widget.size * 0.03),

              // Botão ver detalhes
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _navigateToDetails,
                  icon: Icon(
                    Icons.info_outline,
                    size: widget.size * 0.05,
                    color: const Color(0xFF2E7D32),
                  ),
                  label: Text(
                    'Ver Detalhes',
                    style: TextStyle(
                      fontSize: widget.size * 0.045,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: EdgeInsets.symmetric(vertical: widget.size * 0.03),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
