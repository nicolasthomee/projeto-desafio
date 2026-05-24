// tela principal do app — mostra os 4 módulos via bottom navigation
// tbm gerencia o ciclo de vida do polling de dados (inicia/para c/ a tela)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/producao_provider.dart';
import '../widgets/status_card.dart';
import 'controle_screen.dart';
import 'historico_screen.dart';
import 'relatorios_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _abaSelecionada = 0; // índice da aba ativa (0=dashboard, 1=controle, etc.)

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback: executa após o primeiro frame ser desenhado
    // necessário pq o context com o provider só está disponível depois do build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        // inicia o polling de dados a cada 5s
        context.read<ProducaoProvider>().iniciarPolling(token);
      }
    });
  }

  @override
  void dispose() {
    // para o polling qdo o widget é destruído — evita requests desnecessários
    context.read<ProducaoProvider>().pararPolling();
    super.dispose();
  }

  // faz logout: para o polling, limpa a sessão e vai p/ a tela de login
  Future<void> _logout() async {
    context.read<ProducaoProvider>().pararPolling();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    // pushAndRemoveUntil remove td da pilha — o usuário n consegue voltar
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();   // escuta mudanças de auth
    final producao = context.watch<ProducaoProvider>(); // escuta dados de produção

    // lista de telas — cada índice corresponde a uma aba do nav bar
    final telas = [
      _buildDashboard(producao, auth), // aba 0: painel em tempo real
      ControleScreen(token: auth.token ?? ''),   // aba 1: botões de comando
      HistoricoScreen(token: auth.token ?? ''),  // aba 2: histórico diário
      RelatoriosScreen(token: auth.token ?? ''), // aba 3: relatórios/estatísticas
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento'),
        actions: [
          // badge "ao vivo" — só aparece qdo o polling está ativo
          if (producao.ativo)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Atualizando a cada 5s',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1F34C759), // verde 12% opac
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ponto verde indicando conexão ativa
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Ao vivo',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // botão de logout no canto direito
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      // extendBody: true faz o conteúdo da tela passar por baixo do nav bar
      // necessário p/ o fundo flutuante da pill nav funcionar corretamente
      extendBody: true,
      body: telas[_abaSelecionada], // exibe a tela da aba selecionada
      bottomNavigationBar: _buildPillNav(),
    );
  }

  // ── nav bar em formato de "pílula" flutuante ──────────────────────────────

  Widget _buildPillNav() {
    return Container(
      color: Colors.transparent, // fundo transparente p/ mostrar o conteúdo atrás
      child: SafeArea(
        top: false, // só aplica safe area embaixo (notch inferior)
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32), // bordas bem redondas = pílula
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_outlined,
                    Icons.dashboard_rounded, 'Dashboard'),
                _navItem(1, Icons.tune_outlined,
                    Icons.tune_rounded, 'Controle'),
                _navItem(2, Icons.history_outlined,
                    Icons.history_rounded, 'Histórico'),
                _navItem(3, Icons.bar_chart_outlined,
                    Icons.bar_chart_rounded, 'Relatórios'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // monta cada item da nav bar
  // qdo selecionado: fundo azul claro + label animado aparece
  // qdo n selecionado: só o ícone cinza
  Widget _navItem(
    int index,
    IconData icon,       // ícone qdo n selecionado (outline)
    IconData selectedIcon, // ícone qdo selecionado (preenchido)
    String label,
  ) {
    final selected = _abaSelecionada == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // área de toque maior (inclui espaço vazio)
      onTap: () => setState(() => _abaSelecionada = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // animação suave ao trocar de aba
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x1F007AFF) // fundo azul suave qdo ativo
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF8E8E93),
              size: 22,
            ),
            // o label só aparece qdo o item está selecionado
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── conteúdo da aba dashboard ─────────────────────────────────────────────

  Widget _buildDashboard(ProducaoProvider producao, AuthProvider auth) {
    // estado 1: carregando dados pela primeira vez
    if (producao.carregando) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF007AFF)));
    }

    // estado 2: erro de conexão
    if (producao.erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ícone de wifi desconectado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Color(0x14FF3B30), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded,
                    color: Color(0xFFFF3B30), size: 40),
              ),
              const SizedBox(height: 16),
              Text(producao.erro!,
                  style: const TextStyle(
                      color: Color(0xFF6C6C70), fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // botão p/ tentar novamente — reinicia o polling
              ElevatedButton.icon(
                onPressed: () {
                  final token = auth.token;
                  if (token != null) {
                    context.read<ProducaoProvider>().iniciarPolling(token);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // estado 3: aguardando o primeiro dado chegar do esp32
    if (producao.producao == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0x1F007AFF), shape: BoxShape.circle),
              child: const Icon(Icons.sensors_outlined,
                  color: Color(0xFF007AFF), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Aguardando dados do ESP32...',
                style: TextStyle(color: Color(0xFF6C6C70), fontSize: 15)),
          ],
        ),
      );
    }

    // estado 4: dados disponíveis — exibe o dashboard completo
    final dados    = producao.producao!;
    final corStatus = _corDoStatus(dados.status); // cor baseada no status atual

    return RefreshIndicator(
      color: const Color(0xFF007AFF),
      // arrastar p/ baixo reinicia o polling
      onRefresh: () async {
        final token = auth.token;
        if (token != null) {
          context.read<ProducaoProvider>().iniciarPolling(token);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // permite scroll mesmo c/ pouco conteúdo
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // banner colorido no topo — muda de cor conforme o status da linha
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // gradiente da cor do status p/ versão mais clara
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [corStatus, corStatus.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: corStatus.withValues(alpha: 0.28), // sombra c/ mesma cor do status
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // emoji correspondente ao status (🟢 rodando, 🔴 parada, etc.)
                  Text(dados.statusEmoji,
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dados.status, // ex: "RODANDO", "PARADA"
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Alerta: ${dados.alerta}', // ex: "NORMAL", "SEM_PRODUCAO"
                          style: const TextStyle(
                              color: Color(0xCCFFFFFF), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Métricas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // dois cards de métricas lado a lado usando Row + Expanded
            // Row evita o problema de overflow q o GridView c/ childAspectRatio fixo causava
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StatusCard(
                    titulo: 'PEÇAS PRODUZIDAS',
                    valor: dados.contador.toString(),
                    icone: Icons.inventory_2_rounded,
                    cor: const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatusCard(
                    titulo: 'TEMPO PARADO',
                    valor: '${dados.tempoParado}s',
                    icone: Icons.timer_off_rounded,
                    cor: const Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // horário da última atualização recebida da api
            if (dados.criadoEm != null)
              Center(
                child: Text(
                  'Atualizado às ${_formatarData(dados.criadoEm!)}',
                  style: const TextStyle(
                      color: Color(0xFFAEAEB2), fontSize: 12),
                ),
              ),
            // espaço extra no final p/ o conteúdo n ficar atrás da pill nav
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // retorna a cor correspondente ao status da linha de produção
  Color _corDoStatus(String status) {
    switch (status) {
      case 'RODANDO':   return const Color(0xFF34C759); // verde
      case 'PARADA':    return const Color(0xFFFF3B30); // vermelho
      case 'ALERTA':    return const Color(0xFFFF9500); // laranja
      case 'STANDBY':   return const Color(0xFF007AFF); // azul
      case 'ENCERRADO': return const Color(0xFF8E8E93); // cinza
      default:          return const Color(0xFF8E8E93);
    }
  }

  // formata o datetime p/ mostrar só a hora: "14:35:07"
  String _formatarData(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
