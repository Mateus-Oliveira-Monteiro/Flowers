import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/plant_data.dart';
import '../models/plant_info.dart';
import '../services/firebase_service.dart';
import '../widgets/humidity_gauge.dart';
import '../widgets/sensor_info_card.dart';
import '../widgets/plant_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  SensorData? _currentSensorData;
  PlantData? _currentPlantData;
  PlantInfo? _selectedPlantInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startListening();
    _loadPlantData();
  }

  void _startListening() {
    _firebaseService.getSensorDataStream().listen(
      (sensorData) {
        setState(() {
          _currentSensorData = sensorData;
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: $error';
        });
      },
    );
  }

  void _loadPlantData() async {
    // Não carrega nenhuma planta por padrão
    // O usuário deve selecionar uma planta manualmente
    setState(() {
      _currentPlantData = null;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final sensorData = await _firebaseService.getSensorData();
    // Não recarrega dados da planta no refresh - mantém a seleção do usuário
    setState(() {
      _currentSensorData = sensorData;
      _isLoading = false;
      if (sensorData == null) {
        _errorMessage = 'Não foi possível carregar os dados';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flower Killer'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Carregando dados do sensor...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 400,
        child: Center(
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentSensorData == null) {
      return const SizedBox(
        height: 400,
        child: Center(child: Text('Nenhum dado disponível')),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        // Status da conexão
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50], // Fundo azul claro
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!), // Borda azul
          ),
          child: Row(
            children: [
              Icon(Icons.wifi, color: Colors.blue[800]), // Ícone azul escuro
              const SizedBox(width: 8),
              Text(
                'Conectado ao Firebase',
                style: TextStyle(
                  color: Colors.black, // Texto preto
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Layout responsivo: Gauge e Card da Planta
        LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 600;
            final itemSize = isWideScreen
                ? 250.0
                : (constraints.maxWidth - 48) / 2; // 48 = margins

            if (isWideScreen) {
              // Layout lado a lado para telas maiores
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  HumidityGauge(
                    humidity: _currentSensorData!.umidade.toDouble(),
                    size: itemSize,
                  ),
                  PlantCard(
                    plantData: _currentPlantData,
                    plantInfo: _selectedPlantInfo,
                    size: itemSize,
                    onPlantSelected: (plantInfo) {
                      setState(() {
                        _selectedPlantInfo = plantInfo;
                      });
                    },
                  ),
                ],
              );
            } else {
              // Layout em coluna para telas menores
              return Column(
                children: [
                  PlantCard(
                    plantData: _currentPlantData,
                    plantInfo: _selectedPlantInfo,
                    size: itemSize.clamp(200.0, 280.0),
                    onPlantSelected: (plantInfo) {
                      setState(() {
                        _selectedPlantInfo = plantInfo;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  HumidityGauge(
                    humidity: _currentSensorData!.umidade.toDouble(),
                    size: itemSize.clamp(200.0, 280.0),
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 20),

        // Status da umidade
        _buildHumidityStatus(_currentSensorData!.umidade.toDouble()),

        const SizedBox(height: 20),

        // Card com informações detalhadas
        SensorInfoCard(sensorData: _currentSensorData!),

        const SizedBox(height: 30),

        // Rodapé com créditos
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Foto de perfil circular
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.grey[300],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/images/mateus.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person, size: 40, color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desenvolvido por Mateus Oliveira Monteiro\nTodos os direitos reservados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHumidityStatus(double humidity) {
    String status;
    Color color;
    IconData icon;

    if (humidity < 30) {
      status = 'Solo Seco - Necessita Irrigação';
      color = Colors.red;
      icon = Icons.warning;
    } else if (humidity < 60) {
      status = 'Solo com Umidade Moderada';
      color = Colors.orange;
      icon = Icons.info;
    } else {
      status = 'Solo Bem Hidratado';
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
