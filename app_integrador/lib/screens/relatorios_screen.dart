// tela de relatórios — estatísticas agregadas do período selecionado
// filtros de data + grid de métricas + card de tempo médio parado
// lógica de carregamento e filtros: idêntica à versão anterior
import 'package:flutter/material.dart';
import '../models/relatorio_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_card.dart';

class RelatoriosScreen extends StatefulWidget {
  final String token;
  const RelatoriosScreen({super.key, required this.token});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  RelatorioModel? _relatorio;
  bool    _carregando = true;
  String? _erro;
  String? _dataInicio; // filtro de data início — formato "yyyy-MM-dd"
  String? _dataFim;    // filtro de data fim — formato "yyyy-MM-dd"

  @override
  void initState() {
    super.initState();
    _carregar(); // carrega s/ filtros ao abrir a tela
  }

  // busca o relatório c/ os filtros de data atuais (null = sem filtro)
  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final dados = await ApiService.getRelatorio(
        widget.token,
        dataInicio: _dataInicio,
        dataFim:    _dataFim,
      );
      setState(() => _relatorio = dados);
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _carregando = false);
    }
  }

  // abre o date picker nativo e atualiza o filtro correspondente
  Future<void> _selecionarData({required bool isInicio}) async {
    final data = await showDatePicker(
      context:     context,
      initialDate: DateTime.now(),
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
      // aplica o tema dark no date picker — accent como cor primária
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   C.accent,
            onPrimary: C.bg,
            surface:   C.surface,
            onSurface: C.hi,
          ),
        ),
        child: child!,
      ),
    );
    if (data == null) return; // usuário cancelou o seletor

    // formata p/ "yyyy-MM-dd" q é o formato esperado pela api
    final formatada =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    setState(() {
      if (isInicio) {
        _dataInicio = formatada;
      } else {
        _dataFim = formatada;
      }
    });
    _carregar(); // recarrega automaticamente c/ o novo filtro
  }

  // remove os dois filtros e recarrega td
  void _limparFiltros() {
    setState(() { _dataInicio = null; _dataFim = null; });
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RELATÓRIOS', style: T.heading),
          const SizedBox(height: 16),

          // ── filtros de data ───────────────────────────────────────────────
          Row(
            children: [
              // botão data início
              Expanded(
                child: _botaoData(
                  label:    _dataInicio ?? 'Data início',
                  icone:    Icons.calendar_today_rounded,
                  isActive: _dataInicio != null,
                  onTap:    () => _selecionarData(isInicio: true),
                ),
              ),
              const SizedBox(width: 10),
              // botão data fim
              Expanded(
                child: _botaoData(
                  label:    _dataFim ?? 'Data fim',
                  icone:    Icons.calendar_month_rounded,
                  isActive: _dataFim != null,
                  onTap:    () => _selecionarData(isInicio: false),
                ),
              ),
              // botão limpar filtros — só aparece qdo algum filtro está ativo
              if (_dataInicio != null || _dataFim != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _limparFiltros,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        C.accentA08,
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(color: C.accentA20),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: C.accent, size: 18),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ── estados da tela ───────────────────────────────────────────────
          if (_carregando)
            const Center(child: CircularProgressIndicator(color: C.accent))
          else if (_erro != null)
            Center(
              child: Column(
                children: [
                  Text(_erro!,
                      style: T.bodySec.copyWith(color: C.accent),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:   _carregar,
                    child: const Text('TENTAR NOVAMENTE'),
                  ),
                ],
              ),
            )
          else if (_relatorio != null)
            _buildConteudo(_relatorio!),
        ],
      ),
    );
  }

  // conteúdo principal qdo os dados estão disponíveis
  Widget _buildConteudo(RelatorioModel r) {
    // sem dados no período selecionado
    if (r.totalDias == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: C.accentA08, shape: BoxShape.circle),
                child: const Icon(Icons.bar_chart_rounded,
                    color: C.accent, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Nenhum dado p/ o período.',
                  style: T.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Tente selecionar um período diferente.',
                  style: T.bodySec),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // badge c/ qtd de dias analisados
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:        C.accentA08,
            borderRadius: BorderRadius.circular(6),
            border:       Border.all(color: C.accentA20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.date_range_rounded, color: C.accent, size: 16),
              const SizedBox(width: 8),
              // pluraliza corretamente: "1 dia analisado" / "3 dias analisados"
              Text(
                '${r.totalDias} dia${r.totalDias > 1 ? 's' : ''} '
                'analisado${r.totalDias > 1 ? 's' : ''}',
                style: T.small.copyWith(
                    color: C.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── grid 2x2 de métricas ──────────────────────────────────────────
        // usa StatusCard c/ ícone monocromático (accent) — sem cor diferente p/ cada card
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap:     true,
          physics: const NeverScrollableScrollPhysics(),
          padding:          EdgeInsets.zero,
          crossAxisSpacing: 10,
          mainAxisSpacing:  10,
          childAspectRatio: 1.1, // ligeiramente retangular
          children: [
            StatusCard(
              titulo: 'MÉDIA DE PEÇAS',
              valor:  r.mediaPecas.toStringAsFixed(1), // ex: "42.3"
              icone:  Icons.show_chart_rounded,
            ),
            StatusCard(
              titulo: 'MÁXIMO',
              valor:  r.maximoPecas.toString(),
              icone:  Icons.arrow_upward_rounded,
            ),
            StatusCard(
              titulo: 'MÍNIMO',
              valor:  r.minimoPecas.toString(),
              icone:  Icons.arrow_downward_rounded,
            ),
            StatusCard(
              titulo: 'ALERTAS',
              valor:  r.totalAlertas.toString(),
              icone:  Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── card de tempo médio parado ────────────────────────────────────
        // largura total, separado do grid p/ ter mais destaque
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        C.surface,
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: C.border),
          ),
          child: Row(
            children: [
              // ícone em accent — mesma cor dos outros ícones (regra 3 cores)
              const Icon(Icons.timer_off_rounded, color: C.accent, size: 20),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tempo médio parado', style: T.bodySec),
                  // valor em JetBrains Mono accent — destaque como as métricas
                  Text(
                    '${r.mediaTempoParadoSeg.toStringAsFixed(0)}s por dia',
                    style: T.metricM,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // botão de seleção de data — dark c/ borda; ativo usa accentA08 + accentA20
  Widget _botaoData({
    required String label,
    required IconData icone,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:        isActive ? C.accentA08 : C.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? C.accentA20 : C.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              color: isActive ? C.accent : C.mid,
              size:  16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: T.small.copyWith(
                  color:      isActive ? C.accent : C.mid,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
