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

  // Save default language if not already set / Salva idioma padrão se não estiver definido
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('language')) {
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
    await windowManager.show();
    await windowManager.focus();
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
    final win = appWindow;
    const initialSize = Size(400, 500);
    win.minSize = const Size(350, 450);
    win.maxSize = const Size(450, 550);
    win.size = initialSize;
    win.alignment = Alignment.centerRight;
    win.title = "Tamagotchi Duck";
    win.show();
  });
}

/// Main application widget / Widget principal da aplicação
class TamagotchiDuckApp extends StatelessWidget {
  const TamagotchiDuckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamagotchi Duck',
      debugShowCheckedModeBanner:
          false, // Hide debug banner / Esconder banner de debug
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.blueAccent, // Use a suitable accent color if needed
        ),
        // Custom theme for the widget / Tema customizado para o widget
        scaffoldBackgroundColor: Colors.transparent,
        dialogTheme: DialogThemeData(
            backgroundColor: Colors.white.withValues(alpha: 0.95)),
        cardTheme: CardThemeData(color: Colors.white.withValues(alpha: 0.9)),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
        ),
      ),
      home: const TamagotchiWidget(), // Main widget / Widget principal
      // Remove default material banner / Remove banner padrão do material
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
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: child,
          ),
        );
      },
    );
  }
}
