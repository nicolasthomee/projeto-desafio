// ponto de entrada do app — o flutter começa por aqui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/producao_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

// função principal: sobe o app
void main() {
  runApp(const IotApp());
}

// widget raiz do app — tudo parte daqui
// usa MultiProvider p/ deixar os providers acessíveis em qq tela
class IotApp extends StatelessWidget {
  const IotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // gerencia login/logout em toda a árvore
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // gerencia os dados de produção em tempo real
        ChangeNotifierProvider(create: (_) => ProducaoProvider()),
      ],
      child: MaterialApp(
        title: 'Monitoramento Industrial',
        debugShowCheckedModeBanner: false, // esconde o banner "debug" no canto
        theme: _buildTheme(),
        home: const _TelaInicial(), // primeira tela — decide p/ onde ir
      ),
    );
  }

  // monta o tema visual do app inteiro (cores, fontes, bordas)
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      // paleta de cores baseada no azul apple (#007AFF)
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF),
        brightness: Brightness.light,
        surface: Colors.white,
        primary: const Color(0xFF007AFF),
      ),
      // fundo padrão de todas as telas: cinza claríssimo
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      cardColor: Colors.white,
      // appbar: sem sombra, mesma cor do fundo p/ parecer integrada
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0, // evita mudar de cor ao scrollar
        surfaceTintColor: Color(0xFFF2F2F7),
        foregroundColor: Color(0xFF1C1C1E),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Color(0xFF007AFF)),
      ),
      // estilo da barra de navegação inferior padrão
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: const Color(0x0F000000),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x1F007AFF), // fundo do item selecionado
        // ícone muda de cor dependendo de estar selecionado ou n
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF007AFF));
          }
          return const IconThemeData(color: Color(0xFF8E8E93));
        }),
        // label tbm muda de cor e peso
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF007AFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
    );
  }
}

// tela inicial invisível — só decide p/ onde redirecionar
// se já tem sessão salva, vai direto p/ o dashboard
// se n tem, fica na login
class _TelaInicial extends StatefulWidget {
  const _TelaInicial();

  @override
  State<_TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<_TelaInicial> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback garante q o context já está montado antes de navegar
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSessao());
  }

  // verifica se o token salvo ainda existe
  // se sim, vai p/ dashboard; se n, permanece na login
  Future<void> _verificarSessao() async {
    final auth = context.read<AuthProvider>();
    await auth.inicializar(); // tenta carregar token salvo no dispositivo

    if (!mounted) return; // checa se o widget ainda existe antes de navegar

    if (auth.logado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // enquanto verifica a sessão, mostra a tela de login mesmo
    return const LoginScreen();
  }
}
