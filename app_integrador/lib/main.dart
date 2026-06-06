// ponto de entrada do app — inicializa providers e tema dark
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // p/ SystemChrome (status bar)
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/producao_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart'; // tokens de cor/tipografia + buildAppTheme()

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // faz a status bar ficar transparente e c/ ícones claros (dark mode)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:               Colors.transparent,
    statusBarIconBrightness:      Brightness.light,
    systemNavigationBarColor:     C.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const IotApp());
}

// widget raiz — configura providers e MaterialApp
class IotApp extends StatelessWidget {
  const IotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // gerencia login/logout em toda a árvore
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // gerencia dados de produção em tempo real (polling 5s)
        ChangeNotifierProvider(create: (_) => ProducaoProvider()),
      ],
      child: MaterialApp(
        title: 'Monitoramento Industrial',
        debugShowCheckedModeBanner: false,
        // tema dark industrial — definido em theme/app_theme.dart
        theme: buildAppTheme(),
        home: const _TelaInicial(),
      ),
    );
  }
}

// tela invisível q decide p/ onde redirecionar ao abrir o app
// se já tem sessão salva → dashboard; se n tem → login
class _TelaInicial extends StatefulWidget {
  const _TelaInicial();

  @override
  State<_TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<_TelaInicial> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback garante q o context está montado antes de navegar
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSessao());
  }

  // tenta restaurar sessão salva; se logado, vai p/ dashboard
  Future<void> _verificarSessao() async {
    final auth = context.read<AuthProvider>();
    await auth.inicializar(); // lê token do SharedPreferences

    if (!mounted) return; // garante q o widget ainda existe antes de navegar

    if (auth.logado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
    // se n logado, permanece na LoginScreen (widget build abaixo)
  }

  @override
  Widget build(BuildContext context) {
    // enquanto verifica a sessão, exibe a tela de login (sem flash)
    return const LoginScreen();
  }
}
