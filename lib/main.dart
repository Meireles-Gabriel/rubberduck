import 'dart:io'; // Adicione esta linha
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/tamagotchi_widget.dart';
import 'utils/localization_strings.dart';

void main() async {
  // Inicializa o binding do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o gerenciador de janelas
  await windowManager.ensureInitialized();

  String? systemLocale;
  if (Platform.isWindows) {
    // Fallback para Windows
    systemLocale = null;
  } else {
    // Só tenta obter o locale em plataformas suportadas
    systemLocale = await Devicelocale.currentLocale;
  }

  // Define idioma padrão baseado no idioma do sistema
  String defaultLanguage =
      (systemLocale?.startsWith('pt') ?? false) ? 'pt_BR' : 'en_US';

  // Obtém a instância de shared preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('language')) {
    // Salva idioma padrão se não estiver definido
    await prefs.setString('language', defaultLanguage);
  }

  // Inicializa a localização
  await LocalizationStrings.init();

  // Configura propriedades da janela
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 500), // Tamanho da janela
    center: false, // Não centralizar janela
    backgroundColor: Colors.transparent, // Fundo transparente
    skipTaskbar: true, // Esconder da barra de tarefas
    titleBarStyle: TitleBarStyle.hidden, // Esconder barra de título
    alwaysOnTop: true, // Sempre em primeiro plano
    fullScreen: false, // Não em tela cheia
    minimumSize: Size(350, 450), // Tamanho mínimo
    maximumSize: Size(450, 550), // Tamanho máximo
  );

  // Aplica configuração da janela
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); // Mostra a janela
    await windowManager.focus(); // Foca a janela
    await windowManager.setAsFrameless(); // Remove moldura da janela
    await windowManager.setSkipTaskbar(true); // Pular barra de tarefas
    await windowManager.setAlwaysOnTop(true); // Sempre em primeiro plano
  });

  // Executa a aplicação
  runApp(const TamagotchiDuckApp());

  // Configura janela bitsdojo
  doWhenWindowReady(() {
    final win = appWindow; // Obtém a instância da janela do aplicativo
    const initialSize = Size(400, 500); // Tamanho inicial da janela
    win.minSize = const Size(350, 450); // Tamanho mínimo da janela
    win.maxSize = const Size(450, 550); // Tamanho máximo da janela
    win.size = initialSize; // Define o tamanho inicial
    win.alignment =
        Alignment.bottomRight; // Alinha a janela ao canto inferior direito
    win.title = "Tamagotchi Duck"; // Define o título da janela
    win.show(); // Mostra a janela bitsdojo
  });
}

/// Widget principal da aplicação
class TamagotchiDuckApp extends StatelessWidget {
  const TamagotchiDuckApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Retorna o widget MaterialApp
    return MaterialApp(
      title: 'Tamagotchi Duck', // Título da aplicação
      debugShowCheckedModeBanner: false, // Esconder banner de debug
      // Define o tema da aplicação
      theme: ThemeData(
        // Define o esquema de cores
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.blueAccent,
        ),
        // Tema customizado para o widget
        scaffoldBackgroundColor:
            Colors.transparent, // Fundo transparente do scaffold
        // Tema do diálogo
        dialogTheme: DialogThemeData(
            backgroundColor: Colors.white.withValues(alpha: 0.95)),
        // Tema do cartão
        cardTheme: CardThemeData(color: Colors.white.withValues(alpha: 0.9)),
        // Tema do texto
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
              color: Colors.black87), // Estilo de texto médio do corpo
          bodySmall: TextStyle(
              color: Colors.black54), // Estilo de texto pequeno do corpo
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
                color: Colors.black.withValues(alpha: 0.2), // Cor da sombra
                blurRadius: 10, // Raio do desfoque
                offset: const Offset(0, 5), // Deslocamento da sombra
              ),
            ],
          ),
          child: ClipRRect(
            // Widget para cortar retângulo
            borderRadius: BorderRadius.circular(15), // Raio da borda para corte
            child: child, // Widget filho
          ),
        );
      },
    );
  }
}
