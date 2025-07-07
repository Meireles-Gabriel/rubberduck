# Tamagotchi Duck Widget

Um widget de desktop para Windows criado com Flutter e Flame, apresentando um pato tamagotchi interativo com integração de IA.

A desktop widget for Windows created with Flutter and Flame, featuring an interactive tamagotchi duck with AI integration.

## 🦆 Características / Features

### Português (PT-BR)
- **Widget sem bordas**: Janela customizada que fica sempre em primeiro plano
- **Sistema de cuidados**: Alimente, limpe e brinque com seu pato 3x por dia
- **Animações Flame**: Múltiplas animações sprite para diferentes ações
- **Integração ChatGPT**: Converse com seu pato usando IA
- **Sistema temporal**: Status degradam com base no tempo real
- **Morte e ressurreição**: Pato morre se não for cuidado por 24h
- **Bilíngue**: Suporte para português e inglês
- **Arrastar e soltar**: Arraste itens de cuidado para o pato

### English (EN-US)
- **Borderless widget**: Custom window that stays always on top
- **Care system**: Feed, clean, and play with your duck 3x daily
- **Flame animations**: Multiple sprite animations for different actions
- **ChatGPT integration**: Chat with your duck using AI
- **Time-based system**: Status degrades based on real time
- **Death and revival**: Duck dies if not cared for 24h
- **Bilingual**: Support for Portuguese and English
- **Drag and drop**: Drag care items to the duck

## 🛠️ Instalação / Installation

### Pré-requisitos / Prerequisites
- Flutter SDK (>=3.10.0)
- Windows 10/11
- Visual Studio 2022 (com C++ tools)
- Chave API OpenAI (opcional para chat)

### Passos / Steps

1. **Clone o projeto / Clone the project:**
   ```bash
   git clone <repository-url>
   cd tamagotchi_duck
   ```

2. **Instale dependências / Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Crie assets de sprites / Create sprite assets:**
   - Crie sprites 64x64 pixels para cada animação
   - Salve em `assets/images/sprites/`
   - Nomes necessários: `duck_idle.png`, `duck_feed.png`, `duck_clean.png`, `duck_play.png`, `duck_death.png`

4. **Execute o projeto / Run the project:**
   ```bash
   flutter run -d windows
   ```

## 🎨 Assets Necessários / Required Assets

Você precisa criar os seguintes sprite sheets:
You need to create the following sprite sheets:

- `assets/images/sprites/duck_idle.png` - Animação padrão (4 frames)
- `assets/images/sprites/duck_feed.png` - Animação de comer (6 frames)
- `assets/images/sprites/duck_clean.png` - Animação de limpeza (6 frames)
- `assets/images/sprites/duck_play.png` - Animação de brincar (8 frames)
- `assets/images/sprites/duck_death.png` - Animação de morte (4 frames)

### Ferramentas recomendadas / Recommended tools:
- **Aseprite** (pago/paid): Melhor para pixel art
- **Piskel** (gratuito/free): Editor online
- **GIMP** (gratuito/free): Editor geral

## ⚙️ Configuração / Configuration

### Chave API ChatGPT / ChatGPT API Key
1. Vá para https://platform.openai.com/api-keys
2. Crie uma nova chave API
3. Abra as configurações no widget
4. Cole sua chave API
5. Salve as configurações

### Idioma / Language
- Detecta automaticamente o idioma do sistema
- Pode ser alterado nas configurações
- Suporte para pt_BR e en_US

## 📁 Estrutura do Projeto / Project Structure

```
tamagotchi_duck/
├── lib/
│   ├── main.dart                    # Ponto de entrada / Entry point
│   ├── widgets/
│   │   ├── tamagotchi_widget.dart   # Widget principal / Main widget
│   │   └── settings_page.dart       # Página de configurações / Settings page
│   ├── game/
│   │   ├── duck_game.dart           # Engine Flame / Flame engine
│   │   ├── duck_status.dart         # Sistema de status / Status system
│   │   └── death_revival_system.dart # Sistema morte/vida / Death/revival system
│   ├── services/
│   │   ├── chat_service.dart        # Integração ChatGPT / ChatGPT integration
│   │   └── periodic_tasks.dart      # Tarefas periódicas / Periodic tasks
│   └── utils/
│       └── localization_strings.dart # Strings localizadas / Localized strings
├── assets/
│   └── images/
│       └── sprites/                 # Sprites do pato / Duck sprites
├── windows/
│   └── runner/
│       └── main.cpp                 # Configuração janela / Window configuration
└── pubspec.yaml                     # Dependências / Dependencies
```

## 🔧 Personalização / Customization

### Modificar taxas de degradação / Modify degradation rates:
```dart
// Em duck_status.dart / In duck_status.dart
static const double hungerDecayRate = 4.0; // por hora / per hour
static const double cleanlinessDecayRate = 2.0;
static const double happinessDecayRate = 3.0;
```

### Alterar intervalo de comentários / Change comment interval:
```dart
// Em periodic_tasks.dart / In periodic_tasks.dart
final randomMinutes = Random().nextInt(11) + 10; // 10-20 minutos / minutes
```

## 🐛 Resolução de Problemas / Troubleshooting

### Sprites não carregam / Sprites not loading:
- Verifique se os arquivos estão em `assets/images/sprites/`
- Confirme que os nomes dos arquivos estão corretos
- Execute `flutter pub get` novamente

### Janela não fica sem bordas / Window not borderless:
- Verifique se está executando no Windows
- Compile em modo release para melhor resultado
- Verifique permissões do sistema

### ChatGPT não responde / ChatGPT not responding:
- Verifique sua chave API nas configurações
- Confirme que tem créditos na conta OpenAI
- Verifique conexão com internet

## 📝 Licença / License

Este projeto é fornecido como exemplo educacional. Use por sua própria conta e risco.
This project is provided as educational example. Use at your own risk.

## 🤝 Contribuições / Contributions

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.
Contributions are welcome! Feel free to open issues or pull requests.
