# RubberDuck - AI Desktop Pet

Um widget de desktop para Windows criado com Flutter e Flame, apresentando um pato virtual inteligente com integração de IA que atua como "rubber duck" para produtividade.

A desktop widget for Windows created with Flutter and Flame, featuring an intelligent virtual duck with AI integration that acts as a "rubber duck" for productivity.

## 🦆 Características / Features

### Português (PT-BR)
- **Widget sem bordas**: Janela customizada que fica sempre em primeiro plano (200x250px)
- **Sistema de cuidados**: Alimente, limpe e brinque com seu pato para manter as necessidades
- **Animações Flame**: 7 animações sprite diferentes (idle, blink, fly, look, run, talk, death)
- **Integração ChatGPT**: Converse com seu pato usando IA GPT-4 com análise de tela
- **Sistema temporal realístico**: Status degradam continuamente (fome: 10/h, limpeza: 5/h, felicidade: 7/h)
- **Morte e ressurreição**: Pato morre se não for cuidado por 24 horas
- **Comentários automáticos**: O pato faz observações sobre sua tela a cada 10-20 minutos
- **Bilíngue**: Suporte completo para português e inglês
- **Histórico de conversa**: Memória persistente de até 30 mensagens
- **Sons interativos**: Efeitos sonoros para ações (quack, piu)
- **Configurações persistentes**: Nome do pato e chave API salvos

### English (EN-US)
- **Borderless widget**: Custom window that stays always on top (200x250px)
- **Care system**: Feed, clean, and play with your duck to maintain needs
- **Flame animations**: 7 different sprite animations (idle, blink, fly, look, run, talk, death)
- **ChatGPT integration**: Chat with your duck using GPT-4 AI with screen analysis
- **Realistic time system**: Status continuously degrade (hunger: 10/h, cleanliness: 5/h, happiness: 7/h)
- **Death and revival**: Duck dies if not cared for 24 hours
- **Auto comments**: Duck makes observations about your screen every 10-20 minutes
- **Bilingual**: Complete support for Portuguese and English
- **Conversation history**: Persistent memory of up to 30 messages
- **Interactive sounds**: Sound effects for actions (quack, piu)
- **Persistent settings**: Duck name and API key saved

## 🛠️ Tecnologias / Technologies

- **Flutter 3.19.6**: Framework multiplataforma / Cross-platform framework
- **Flame 1.17.0**: Engine de jogos 2D para animações / 2D game engine for animations
- **Riverpod 2.5.1**: Gerenciamento de estado reativo / Reactive state management
- **Window Manager 0.3.9**: Janelas customizadas sem bordas / Borderless custom windows
- **Audioplayers 6.0.0**: Sistema de áudio para efeitos sonoros / Audio system for sound effects
- **HTTP 1.2.1**: Requisições para API do ChatGPT / HTTP requests for ChatGPT API
- **Screen Capturer 0.2.3**: Captura de tela para análise de IA / Screen capture for AI analysis
- **Shared Preferences 2.2.3**: Persistência de configurações locais / Local settings persistence

## 🎨 Assets

### Sprites
- `duck_idle.png` - Animação padrão / Default animation
- `duck_blink.png` - Piscadas ocasionais / Occasional blinks
- `duck_fly.png` - Movimento voando / Flying movement
- `duck_look.png` - Olhando ao redor / Looking around
- `duck_run.png` - Corrida energética / Energetic running
- `duck_talk.png` - Falando no chat / Talking in chat
- `duck_death.png` - Estado de morte / Death state

### Audio
- `quack.wav` - Som de interação principal / Main interaction sound
- `piu.wav` - Som de ação secundária / Secondary action sound

### UI
- `background.png` - Fundo do widget / Widget background
- Elementos de UI para botões e interface / UI elements for buttons and interface

## 📦 Instalação / Installation

### Pré-requisitos / Prerequisites
- Flutter SDK (>=3.10.0)
- Windows 10/11
- Visual Studio 2022 (com C++ tools)
- Chave API OpenAI (opcional para chat)

### Passos / Steps

1. **Clone o projeto / Clone the project:**
   ```bash
   git clone <repository-url>
   cd rubberduck
   ```

2. **Instale dependências / Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure chave API (opcional) / Configure API key (optional):**
   - Execute o projeto e vá para configurações
   - Adicione sua chave OpenAI API para funcionalidade de chat
   - Run the project and go to settings
   - Add your OpenAI API key for chat functionality

4. **Execute o projeto / Run the project:**
   ```bash
   flutter run -d windows
   ```

## ⚙️ Configuração / Configuration

### Chave API ChatGPT / ChatGPT API Key
1. Vá para https://platform.openai.com/api-keys
2. Crie uma nova chave API
3. Abra as configurações no widget (ícone de engrenagem)
4. Cole sua chave API
5. Salve as configurações

### Idioma / Language
- Detecta automaticamente o idioma do sistema
- Pode ser alterado nas configurações
- Suporte para pt_BR e en_US

### Limpeza do Histórico / Clear History
- Use o botão "Limpar Histórico" nas configurações para resetar conversas
- Use the "Clear History" button in settings to reset conversations

## 📁 Estrutura do Projeto / Project Structure

```
rubberduck/
├── lib/
│   ├── main.dart                    # Configuração de janela e app / Window config and app
│   ├── widgets/
│   │   ├── tamagotchi_widget.dart   # Widget principal do pato / Main duck widget
│   │   └── settings_page.dart       # Página de configurações / Settings page
│   ├── game/
│   │   ├── duck_game.dart           # Engine Flame com animações / Flame engine with animations
│   │   ├── duck_status.dart         # Sistema de status com decay / Status system with decay
│   │   └── death_revival_system.dart # Sistema morte/vida / Death/revival system
│   ├── services/
│   │   ├── chat_service.dart        # Integração ChatGPT + histórico / ChatGPT + history integration
│   │   └── periodic_tasks.dart      # Comentários automáticos / Auto comments
│   └── utils/
│       └── localization_strings.dart # Strings PT/EN / PT/EN strings
├── assets/
│   ├── images/
│   │   ├── background.png           # Fundo do widget / Widget background
│   │   ├── sprites/                 # 7 animações do pato / 7 duck animations
│   │   └── ui/                      # Elementos da interface / UI elements
│   └── audio/
│       ├── quack.wav               # Som principal / Main sound
│       └── piu.wav                 # Som secundário / Secondary sound
├── windows/runner/                  # Configuração Windows / Windows configuration
└── pubspec.yaml                     # Dependências do projeto / Project dependencies
```

## 🔧 Personalização / Customization

### Modificar taxas de degradação / Modify degradation rates:
```dart
// Em duck_status.dart / In duck_status.dart
static const double hungerDecayRate = 10.0; // por hora / per hour
static const double cleanlinessDecayRate = 5.0;
static const double happinessDecayRate = 7.0;
static const int deathThresholdMinutes = 1440; // 24 horas / 24 hours
```

### Alterar intervalo de comentários / Change comment interval:
```dart
// Em periodic_tasks.dart / In periodic_tasks.dart
final randomMinutes = Random().nextInt(11) + 10; // 10-20 minutos / minutes
```

### Configurar tamanho da janela / Configure window size:
```dart
// Em main.dart / In main.dart
await windowManager.setSize(const Size(200, 250)); // Tamanho fixo / Fixed size
```

## 🐛 Resolução de Problemas / Troubleshooting

### Assets não carregam / Assets not loading:
- Verifique se os arquivos estão em `assets/images/sprites/` e `assets/audio/`
- Confirme que o `pubspec.yaml` inclui todos os assets
- Execute `flutter clean` e `flutter pub get`

### Janela não fica sem bordas / Window not borderless:
- Verifique se está executando no Windows
- Compile em modo release para melhor resultado: `flutter build windows`
- Verifique permissões do sistema para apps sem bordas

### ChatGPT não responde / ChatGPT not responding:
- Verifique sua chave API nas configurações (ícone de engrenagem)
- Confirme que tem créditos na conta OpenAI
- Verifique conexão com internet
- Teste a chave API em https://platform.openai.com/playground

### Pato não revive / Duck doesn't revive:
- Clique no pato morto para revivê-lo
- Aguarde alguns segundos para sincronização de status
- Verifique se o status foi restaurado para valores iniciais

### Áudio não funciona / Audio not working:
- Verifique se os arquivos `quack.wav` e `piu.wav` existem em `assets/audio/`
- Confirme que o volume do sistema não está mudo
- Teste com outros aplicativos de áudio

## 📝 Licença / License

Este projeto é fornecido como exemplo educacional. Use por sua própria conta e risco.
This project is provided as educational example. Use at your own risk.

## 🤝 Contribuições / Contributions

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.
Contributions are welcome! Feel free to open issues or pull requests.
