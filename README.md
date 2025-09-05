# Flower Killer - Monitoramento de Umidade do Solo

Este é um aplicativo Flutter que monitora a umidade do solo em tempo real através do Firebase Realtime Database e fornece informações detalhadas sobre plantas usando a API da OpenAI.

## Funcionalidades

- 🌱 Monitoramento em tempo real da umidade do solo
- 📊 Visualização em formato de velocímetro (0-100%)
- 🔄 Atualização automática dos dados a cada 2 segundos
- 📱 Interface responsiva e intuitiva
- ⚠️ Alertas visuais baseados no nível de umidade
- 🔍 Busca de plantas usando IA (Google Gemini)
- 💾 Cache de informações de plantas para otimização
- 🎨 Layout adaptável para diferentes tamanhos de tela

## Estrutura do Projeto

```
lib/
├── main.dart                     # Ponto de entrada do app
├── models/
│   ├── sensor_data.dart          # Modelo de dados do sensor
│   ├── plant_data.dart           # Modelo de dados da planta (legado)
│   └── plant_info.dart           # Modelo de informações da planta (OpenAI)
├── screens/
│   ├── home_screen.dart          # Tela principal
│   ├── plant_detail_screen.dart  # Tela de detalhes da planta
│   └── plant_search_screen.dart  # Tela de busca de plantas
├── services/
│   ├── firebase_service.dart     # Serviço de conexão Firebase
│   ├── plant_service.dart        # Serviço de plantas (legado)
│   └── gemini_service.dart       # Serviço da API Google Gemini
└── widgets/
    ├── humidity_gauge.dart       # Widget do velocímetro
    ├── sensor_info_card.dart     # Card de informações do sensor
    ├── plant_card.dart           # Card da planta com busca
    └── sunflower_widget.dart     # Widget personalizado do girassol
```

## Configuração

### 1. Firebase

- **URL do Database**: `https://umidade-solo-default-rtdb.firebaseio.com/`
- **Estrutura dos dados**:
  ```json
  {
    "sensor": {
      "raw": 773,
      "timestamp": 1724712795000,
      "umidade": 42
    }
  }
  ```

### 2. Google Gemini API

1. Copie o arquivo `.env.example` para `.env`
2. Obtenha sua chave da API em [Google AI Studio](https://makersuite.google.com/app/apikey)
3. Substitua `sua_chave_do_gemini_aqui` pela sua chave real no arquivo `.env`

## Como usar

1. Clone o projeto
2. Configure o arquivo `.env` com sua chave do Gemini
3. Execute `flutter pub get` para instalar as dependências
4. Execute `flutter run` para rodar o aplicativo

## Funcionalidades da Busca de Plantas

- **Busca por IA**: Digite o nome de qualquer planta e receba informações detalhadas
- **Cache inteligente**: Evita requisições repetidas salvando resultados localmente
- **Informações completas**:
  - Descrição da planta
  - Exposição ao sol necessária
  - Frequência de rega
  - Tipo de solo ideal
  - Dificuldade de cultivo
  - Cuidados especiais

## Dependências

- `http`: Para requisições HTTP
- `firebase_database`: Para integração com Firebase Realtime Database
- `firebase_core`: Core do Firebase
- `flutter_dotenv`: Para carregar variáveis de ambiente
- `shared_preferences`: Para cache local de dados

## Status da Umidade

- 🔴 **0-29%**: Solo Seco - Necessita Irrigação
- 🟡 **30-59%**: Solo com Umidade Moderada
- 🟢 **60-100%**: Solo Bem Hidratado

## Segurança

- ✅ Chave da API protegida em arquivo `.env`
- ✅ Arquivo `.env` incluído no `.gitignore`
- ✅ Cache local para reduzir uso da API
- ✅ Tratamento de erros robusto
