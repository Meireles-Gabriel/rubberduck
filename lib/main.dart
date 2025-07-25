import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/tamagotchi_widget.dart';
import 'utils/localization_strings.dart';

void main() async {
  // Necessário para garantir que todos os plugins nativos sejam inicializados antes de usar APIs do sistema
  WidgetsFlutterBinding.ensureInitialized();

  // Necessário para permitir controle personalizado da janela (tamanho, posição, sempre no topo)
  await windowManager.ensureInitialized();

  // Detecta o idioma do sistema para oferecer uma experiência localizada automática
  final List<Locale> systemLocales = ui.PlatformDispatcher.instance.locales;
  final String systemLocale =
      systemLocales.isNotEmpty ? systemLocales.first.toString() : '';

  // Inglês como fallback para garantir que o app funcione mesmo em idiomas não suportados
  String defaultLanguage = 'en_US'; // Começa com en_US como fallback

  // Detecta português brasileiro para oferecer experiência nativa aos usuários brasileiros
  if (systemLocale.toLowerCase().contains('pt') ||
      systemLocale.toLowerCase().contains('portuguese')) {
    defaultLanguage = 'pt_BR';
  }

  // SharedPreferences para persistir configurações entre sessões e inicializações
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('language')) {
    // Define idioma inicial apenas se não existir configuração prévia do usuário
    await prefs.setString('language', defaultLanguage);
  }

  // Carrega strings localizadas antes de construir a UI para evitar textos em branco
  await LocalizationStrings.init();

  // Configura janela pequena e sempre visível para simular comportamento de pet de desktop
  WindowOptions windowOptions = const WindowOptions(
    size: Size(
        200, 250), // Tamanho pequeno para não interferir no trabalho do usuário
    center:
        false, // Usuário pode posicionar onde preferir, não força centralização
    backgroundColor:
        Colors.transparent, // Permite janela com bordas arredondadas e sombra
    skipTaskbar: true, // Comporta-se como overlay, não como aplicação normal
    titleBarStyle:
        TitleBarStyle.hidden, // Remove barra de título para visual limpo
    alwaysOnTop: true, // Essencial para pet desktop - sempre visível
    fullScreen: false, // Mantém tamanho pequeno, não deve dominar a tela
    minimumSize: Size(175,
        225), // Evita que seja redimensionada demais e perca funcionalidade
    maximumSize: Size(
        225, 275), // Limita crescimento para manter propósito de pet compacto
  );

  // Aguarda configuração completa antes de mostrar para evitar janela malformada
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); // Torna janela visível após configuração
    await windowManager.focus(); // Chama atenção inicial do usuário
    await windowManager
        .setAsFrameless(); // Remove bordas do sistema para design personalizado
    await windowManager
        .setSkipTaskbar(true); // Reforça comportamento de overlay
    await windowManager.setAlwaysOnTop(true); // Reforça visibilidade constante
  });

  // Riverpod necessário para gerenciamento de estado reativo entre componentes
  runApp(ProviderScope(child: const TamagotchiDuckApp()));

  // BitsDojo oferece controle adicional de janela que window_manager não fornece
  doWhenWindowReady(() {
    final win =
        appWindow; // Acesso direto à janela para configurações avançadas
    const initialSize =
        Size(200, 250); // Mantém consistência com window_manager
    win.minSize =
        const Size(175, 225); // Evita quebra de layout em tamanhos pequenos
    win.maxSize =
        const Size(225, 275); // Mantém foco no conceito de pet compacto
    win.size = initialSize; // Aplica tamanho padrão
    win.alignment =
        Alignment.topRight; // Posição padrão que não interfere no trabalho
    win.title = "Tamagotchi Duck"; // Título para identificação do processo
    win.show(); // Confirma visibilidade com BitsDojo
  });
}

/// Aplicação principal que gerencia o tema e a estrutura visual geral
/// Necessária para configurar o MaterialApp com tema personalizado que suporte transparência
class TamagotchiDuckApp extends StatefulWidget {
  const TamagotchiDuckApp({super.key});

  @override
  State<TamagotchiDuckApp> createState() => _TamagotchiDuckAppState();
}

/// State que monitora mudanças de locale do sistema para atualização automática do idioma
class _TamagotchiDuckAppState extends State<TamagotchiDuckApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Observer necessário para detectar mudanças de idioma do sistema em tempo real
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove observer para evitar vazamentos de memória
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // Reconstrói interface quando usuário muda idioma do sistema
    setState(() {}); // Rebuild when system locale changes
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:
          'Tamagotchi Duck', // Título para identificação nos processos do sistema
      debugShowCheckedModeBanner:
          false, // Remove banner debug para visual limpo em produção
      // Tema configurado para suportar transparência e estética de pet desktop
      theme: ThemeData(
        // Esquema de cores azuis para transmitir calma e diversão
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.blueAccent,
        ),
        // Fundo transparente essencial para efeito de janela flutuante
        scaffoldBackgroundColor:
            Colors.transparent, // Fundo transparente do scaffold
        // Diálogos semi-transparentes para manter consistência visual
        dialogTheme: DialogThemeData(
            backgroundColor: Colors.white.withValues(alpha: 0.95)),
        // Cards semi-transparentes para elementos de UI
        cardTheme: CardThemeData(color: Colors.white.withValues(alpha: 0.9)),
        // Texto escuro para legibilidade em fundos claros
        textTheme: const TextTheme(
          bodyMedium:
              TextStyle(color: Colors.black87), // Texto principal legível
          bodySmall: TextStyle(color: Colors.black54), // Texto secundário suave
        ),
      ),
      home:
          const TamagotchiWidget(), // Widget principal que contém toda a lógica do pet
      // Builder customizado para criar container com bordas arredondadas e sombra
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            // Bordas arredondadas para aparência moderna e amigável
            borderRadius: BorderRadius.circular(15),
            // Fundo semi-transparente para visibilidade sem obstrução total
            color: Colors.white.withValues(alpha: 0.95),
            // Sombra para destacar janela do fundo e dar profundidade
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), // Sombra suave
                blurRadius: 10, // Desfoque para efeito natural
                offset: const Offset(0, 5), // Posicionamento da sombra
              ),
            ],
          ),
          child: ClipRRect(
            // Corta conteúdo nas bordas arredondadas para evitar overflow
            borderRadius:
                BorderRadius.circular(15), // Mantém consistência com container
            child: child, // Widget filho (TamagotchiWidget)
          ),
        );
      },
    );
  }
}
