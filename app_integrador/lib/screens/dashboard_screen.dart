// tela principal — hub das 4 abas + painel de status industrial
// lógica de polling e navegação: idêntica à versão anterior
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/producao_provider.dart';
import '../models/producao_model.dart';
import '../widgets/status_card.dart';
import '../theme/app_theme.dart';
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
  int _abaSelecionada = 0; // índice da aba ativa na pill nav

  @override
  void initState() {
    super.initState();
    // inicia o polling após o primeiro frame (context já montado)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ProducaoProvider>().iniciarPolling(token);
      }
    });
  }

  @override
  void dispose() {
    // para o polling ao sair do dashboard — economiza bateria e dados
    context.read<ProducaoProvider>().pararPolling();
    super.dispose();
  }

  // faz logout: para polling, limpa auth e volta p/ login
  Future<void> _logout() async {
    context.read<ProducaoProvider>().pararPolling();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // instancia a tela da aba selecionada — evita construir telas não visitadas
  Widget _buildTela(int index, AuthProvider auth, ProducaoProvider producao) {
    switch (index) {
      case 0:  return _buildDashboard(producao, auth);
      case 1:  return ControleScreen(token: auth.token ?? '');
      case 2:  return HistoricoScreen(token: auth.token ?? '');
      case 3:  return RelatoriosScreen(token: auth.token ?? '');
      default: return _buildDashboard(producao, auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final producao = context.watch<ProducaoProvider>();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('MONITORAMENTO'),
        actions: [
          // badge "Ao vivo" — aparece só qdo o polling está ativo
          if (producao.ativo)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Atualizando a cada 5s',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        C.accentA08,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: C.accentA20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ponto LED ciano — indica conexão ativa
                      Container(
                        width:  6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: C.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text('Ao vivo',
                          style: T.small.copyWith(
                              color: C.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          // botão de logout
          IconButton(
            icon:    const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      extendBody: true, // permite q o conteúdo passe por baixo da pill nav
      body: _buildTela(_abaSelecionada, auth, producao),
      bottomNavigationBar: _buildPillNav(),
    );
  }

  // ── pill navigation ──────────────────────────────────────────────────────────
  // flutuante, dark elevado, borda sutil — sem o BottomNavigationBar padrão do Material
  Widget _buildPillNav() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color:        C.surfaceHi, // levemente mais claro q o bg
              borderRadius: BorderRadius.circular(30),
              border:       Border.all(color: C.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_outlined,  Icons.dashboard_rounded,  'Dashboard'),
                _navItem(1, Icons.tune_outlined,       Icons.tune_rounded,        'Controle'),
                _navItem(2, Icons.history_outlined,    Icons.history_rounded,     'Histórico'),
                _navItem(3, Icons.bar_chart_outlined,  Icons.bar_chart_rounded,   'Relatórios'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // item individual da pill nav
  // selecionado: fundo accentA08 + borda accentA20 + texto accent
  // inativo:     só ícone em C.mid
  Widget _navItem(int index, IconData icon, IconData selectedIcon, String label) {
    final selected = _abaSelecionada == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _abaSelecionada = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 12,
          vertical:   8,
        ),
        decoration: BoxDecoration(
          color:        selected ? C.accentA08 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:       selected ? Border.all(color: C.accentA20) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? C.accent : C.mid,
              size:  20,
            ),
            // label só aparece na aba selecionada
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: T.small.copyWith(
                  color:      C.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── conteúdo da aba dashboard ────────────────────────────────────────────────
  Widget _buildDashboard(ProducaoProvider producao, AuthProvider auth) {
    // estado 1: carregando pela primeira vez
    if (producao.carregando) {
      return const Center(
          child: CircularProgressIndicator(color: C.accent));
    }

    // estado 2: erro de conexão
    if (producao.erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ícone de erro em container accent sutil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: C.accentA08, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded,
                    color: C.accent, size: 40),
              ),
              const SizedBox(height: 16),
              Text(producao.erro!,
                  style: T.bodySec, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // botão de retry — reinicia o polling
              ElevatedButton.icon(
                onPressed: () {
                  final token = auth.token;
                  if (token != null) {
                    context.read<ProducaoProvider>().iniciarPolling(token);
                  }
                },
                icon:  const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('TENTAR NOVAMENTE'),
              ),
            ],
          ),
        ),
      );
    }

    // estado 3: aguardando o primeiro dado do ESP32
    if (producao.producao == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: C.accentA08, shape: BoxShape.circle),
              child: const Icon(Icons.sensors_outlined,
                  color: C.accent, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Aguardando dados do ESP32...', style: T.bodySec),
          ],
        ),
      );
    }

    // estado 4: dados disponíveis — painel industrial
    final dados = producao.producao!;

    return RefreshIndicator(
      color:     C.accent,
      onRefresh: () async {
        final token = auth.token;
        if (token != null) {
          context.read<ProducaoProvider>().iniciarPolling(token);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── painel de status da linha ──────────────────────────────────
            // estilo de indicador industrial: borda esquerda colorida + LED
            _buildStatusPanel(dados),
            const SizedBox(height: 24),

            // ── métricas ───────────────────────────────────────────────────
            Text('MÉTRICAS', style: T.sectionLabel),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StatusCard(
                    titulo: 'PEÇAS PRODUZIDAS',
                    valor:  dados.contador.toString(),
                    icone:  Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatusCard(
                    titulo: 'TEMPO PARADO',
                    valor:  '${dados.tempoParado}s',
                    icone:  Icons.timer_off_rounded,
                  ),
                ),
              ],
            ),

            // ── timestamp de atualização ───────────────────────────────────
            if (dados.criadoEm != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Atualizado às ${_formatarHora(dados.criadoEm!)}',
                  style: T.small,
                ),
              ),
            ],
            const SizedBox(height: 100), // espaço p/ a pill nav flutuante
          ],
        ),
      ),
    );
  }

  // ── painel de status industrial ──────────────────────────────────────────────
  // borda esquerda colorida = principal indicador visual do estado da linha
  // LED (ponto) + ícone + texto — s/ mudar a cor base do componente
  Widget _buildStatusPanel(ProducaoModel dados) {
    final st = StatusStyle.of(dados.status); // estilo c/ base no status

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(8),
        // borda esquerda em accent = indicador principal; demais bordas em border
        border: Border(
          left:   BorderSide(color: st.borderL, width: 3),
          top:    const BorderSide(color: C.border),
          right:  const BorderSide(color: C.border),
          bottom: const BorderSide(color: C.border),
        ),
      ),
      child: Row(
        children: [
          // LED — ponto que indica atividade; glow qdo accent 100%
          Container(
            width:  10,
            height: 10,
            decoration: BoxDecoration(
              color: st.led,
              shape: BoxShape.circle,
              // glow só qdo o LED está em accent pleno (linha ativa)
              boxShadow: st.led == C.accent
                  ? const [BoxShadow(
                      color:       C.accentA20,
                      blurRadius:  8,
                      spreadRadius: 2,
                    )]
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // status e alerta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // linha 1: ícone + status em JetBrains Mono
                Row(
                  children: [
                    Icon(st.icon, color: st.text, size: 14),
                    const SizedBox(width: 6),
                    Text(dados.status,
                        style: T.statusText.copyWith(color: st.text)),
                  ],
                ),
                const SizedBox(height: 2),
                // linha 2: alerta em texto secundário
                Text('Alerta: ${dados.alerta}', style: T.small),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // formata DateTime p/ "HH:MM:SS" — exibido no timestamp de atualização
  String _formatarHora(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
