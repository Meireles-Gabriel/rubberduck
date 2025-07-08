import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/tamagotchi_widget.dart';
import 'utils/localization_strings.dart';

void main() async {
  // Initialize Flutter binding / Inicializa o binding do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager / Inicializa o gerenciador de janelas
  await windowManager.ensureInitialized();

  // Detect system locale / Detecta o idioma do sistema
  String? systemLocale = await Devicelocale.currentLocale;

  // Set default language based on system locale / Define idioma padrão baseado no idioma do sistema
  String defaultLanguage =
      (systemLocale?.startsWith('pt') ?? false) ? 'pt_BR' : 'en_US';

  // Get shared preferences instance / Obtém a instância de shared preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('language')) {
    // Save default language if not already set / Salva idioma padrão se não estiver definido
    await prefs.setString('language', defaultLanguage);
  }

  // Initialize localization / Inicializa a localização
  await LocalizationStrings.init();

  // Configure window properties / Configura propriedades da janela
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 500), // Window size / Tamanho da janela
    center: false, // Don't center window / Não centralizar janela
    backgroundColor:
        Colors.transparent, // Transparent background / Fundo transparente
    skipTaskbar: true, // Hide from taskbar / Esconder da barra de tarefas
    titleBarStyle:
        TitleBarStyle.hidden, // Hide title bar / Esconder barra de título
    alwaysOnTop: true, // Always on top / Sempre em primeiro plano
    fullScreen: false, // Not fullscreen / Não em tela cheia
    minimumSize: Size(350, 450), // Minimum size / Tamanho mínimo
    maximumSize: Size(450, 550), // Maximum size / Tamanho máximo
  );

  // Apply window configuration / Aplica configuração da janela
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); // Show the window / Mostra a janela
    await windowManager.focus(); // Focus the window / Foca a janela
    await windowManager
        .setAsFrameless(); // Remove window frame / Remove moldura da janela
    await windowManager
        .setSkipTaskbar(true); // Skip taskbar / Pular barra de tarefas
    await windowManager
        .setAlwaysOnTop(true); // Always on top / Sempre em primeiro plano
  });

  // Run the application / Executa a aplicação
  runApp(const TamagotchiDuckApp());

  // Configure bitsdojo window / Configura janela bitsdojo
  doWhenWindowReady(() {
    final win =
        appWindow; // Get the app window instance / Obtém a instância da janela do aplicativo
    const initialSize =
        Size(400, 500); // Initial window size / Tamanho inicial da janela
    win.minSize =
        const Size(350, 450); // Minimum window size / Tamanho mínimo da janela
    win.maxSize =
        const Size(450, 550); // Maximum window size / Tamanho máximo da janela
    win.size = initialSize; // Set initial size / Define o tamanho inicial
    win.alignment = Alignment
        .centerRight; // Align window to center right / Alinha a janela ao centro-direita
    win.title =
        "Tamagotchi Duck"; // Set window title / Define o título da janela
    win.show(); // Show the bitsdojo window / Mostra a janela bitsdojo
  });
}

/// Main application widget / Widget principal da aplicação
class TamagotchiDuckApp extends StatelessWidget {
  const TamagotchiDuckApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Returns the MaterialApp widget / Retorna o widget MaterialApp
    return MaterialApp(
      title: 'Tamagotchi Duck', // Application title / Título da aplicação
      debugShowCheckedModeBanner:
          false, // Hide debug banner / Esconder banner de debug
      // Define the application theme / Define o tema da aplicação
      theme: ThemeData(
        // Define the color scheme / Define o esquema de cores
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.blueAccent, // Use a suitable accent color if needed
        ),
        // Custom theme for the widget / Tema customizado para o widget
        scaffoldBackgroundColor: Colors
            .transparent, // Transparent scaffold background / Fundo transparente do scaffold
        // Dialog theme / Tema do diálogo
        dialogTheme: DialogThemeData(
            backgroundColor: Colors.white.withValues(alpha: 0.95)),
        // Card theme / Tema do cartão
        cardTheme: CardThemeData(color: Colors.white.withValues(alpha: 0.9)),
        // Text theme / Tema do texto
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
              color: Colors
                  .black87), // Medium body text style / Estilo de texto médio do corpo
          bodySmall: TextStyle(
              color: Colors
                  .black54), // Small body text style / Estilo de texto pequeno do corpo
        ),
      ),
      home: const TamagotchiWidget(), // Main widget / Widget principal
      // Builder for custom app container / Construtor para container customizado do aplicativo
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            // Rounded corners / Cantos arredondados
            borderRadius: BorderRadius.circular(15),
            // Semi-transparent background / Fundo semi-transparente
            color: Colors.white.withValues(alpha: 0.95),
            // Shadow effect / Efeito de sombra
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.2), // Shadow color / Cor da sombra
                blurRadius: 10, // Blur radius / Raio do desfoque
                offset: const Offset(
                    0, 5), // Offset of the shadow / Deslocamento da sombra
              ),
            ],
          ),
          child: ClipRRect(
            // Clip rectangular widget / Widget para cortar retângulo
            borderRadius: BorderRadius.circular(
                15), // Border radius for clipping / Raio da borda para corte
            child: child, // Child widget / Widget filho
          ),
        );
      },
    );
  }
}
