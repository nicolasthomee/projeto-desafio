// tela de relatórios — estatísticas agregadas do período selecionado
// filtros de data + grid de métricas + card de tempo médio parado
import 'package:flutter/material.dart';
import '../models/relatorio_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
  String? _dataInicio;
  String? _dataFim;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

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

  Future<void> _selecionarData({required bool isInicio}) async {
    final data = await showDatePicker(
      context:     context,
      initialDate: DateTime.now(),
      firstDate:   DateTime(2024),
      lastDate:    DateTime.now(),
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
    if (data == null) return;
    final formatada =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    setState(() {
      if (isInicio) _dataInicio = formatada;
      else          _dataFim    = formatada;
    });
    _carregar();
  }

  void _limparFiltros() {
    setState(() { _dataInicio = null; _dataFim = null; });
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // título + badge de período inline
          Row(
            children: [
              Text('RELATÓRIOS', style: T.heading),
              if (_relatorio != null && _relatorio!.totalDias > 0) ...[
                const SizedBox(width: 10),
                _buildPeriodoBadge(_relatorio!.totalDias),
              ],
            ],
          ),
          const SizedBox(height: 12),

          _buildFiltros(),
          const SizedBox(height: 14),

          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: C.accent),
              ),
            )
          else if (_erro != null)
            _buildErro()
          else if (_relatorio != null)
            _buildConteudo(_relatorio!),
        ],
      ),
    );
  }

  // badge pequeno com contagem de dias — fica inline ao título
  Widget _buildPeriodoBadge(int dias) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        C.accentA08,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: C.accentA20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range_rounded, color: C.accent, size: 11),
          const SizedBox(width: 4),
          Text(
            '$dias dia${dias > 1 ? 's' : ''}',
            style: T.small.copyWith(
                color: C.accent, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Row(
      children: [
        Expanded(
          child: _botaoData(
            label:    _dataInicio ?? 'Data início',
            icone:    Icons.calendar_today_rounded,
            isActive: _dataInicio != null,
            onTap:    () => _selecionarData(isInicio: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _botaoData(
            label:    _dataFim ?? 'Data fim',
            icone:    Icons.calendar_month_rounded,
            isActive: _dataFim != null,
            onTap:    () => _selecionarData(isInicio: false),
          ),
        ),
        if (_dataInicio != null || _dataFim != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _limparFiltros,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color:        C.accentA08,
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: C.accentA20),
              ),
              child: const Icon(Icons.close_rounded, color: C.accent, size: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        children: [
          Text(_erro!,
              style: T.bodySec.copyWith(color: C.accent),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _carregar,
            child: const Text('TENTAR NOVAMENTE'),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo(RelatorioModel r) {
    if (r.totalDias == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                    color: C.accentA08, shape: BoxShape.circle),
                child: const Icon(Icons.bar_chart_rounded,
                    color: C.accent, size: 36),
              ),
              const SizedBox(height: 14),
              Text('Nenhum dado p/ o período.',
                  style: T.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Tente selecionar um período diferente.', style: T.bodySec),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PRODUÇÃO', style: T.sectionLabel),
        const SizedBox(height: 8),

        // grid 2x2 com cards compactos horizontais
        GridView.count(
          crossAxisCount:   2,
          shrinkWrap:       true,
          physics:          const NeverScrollableScrollPhysics(),
          padding:          EdgeInsets.zero,
          crossAxisSpacing: 8,
          mainAxisSpacing:  8,
          childAspectRatio: 1.65,
          children: [
            _metricCard(
              Icons.show_chart_rounded,
              'MÉDIA DE PEÇAS',
              r.mediaPecas.toStringAsFixed(1),
              'por dia',
            ),
            _metricCard(
              Icons.arrow_upward_rounded,
              'MÁXIMO',
              r.maximoPecas.toString(),
              'peças',
            ),
            _metricCard(
              Icons.arrow_downward_rounded,
              'MÍNIMO',
              r.minimoPecas.toString(),
              'peças',
            ),
            _metricCard(
              Icons.warning_amber_rounded,
              'ALERTAS',
              r.totalAlertas.toString(),
              'no período',
            ),
          ],
        ),
        const SizedBox(height: 8),

        // card tempo parado — largura total, estilo separado
        _tempoParadoCard(r.mediaTempoParadoSeg),
      ],
    );
  }

  // card métrica compacto: ícone + rótulo em linha, valor + unidade abaixo
  Widget _metricCard(IconData icon, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: C.accent, size: 12),
              const SizedBox(width: 5),
              Expanded(
                child: Text(label,
                    style:    T.sectionLabel,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: T.metricM),
                TextSpan(
                  text: ' $unit',
                  style: T.small.copyWith(fontSize: 10, color: C.low),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // card largura total com ícone em círculo accent sutil
  Widget _tempoParadoCard(double tempoSeg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: C.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color:  C.accentA08,
              shape:  BoxShape.circle,
            ),
            child: const Icon(Icons.timer_off_rounded,
                color: C.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TEMPO MÉDIO PARADO', style: T.sectionLabel),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: tempoSeg.toStringAsFixed(0),
                      style: T.metricM,
                    ),
                    TextSpan(
                      text: 's por dia',
                      style: T.small.copyWith(fontSize: 10, color: C.low),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoData({
    required String label,
    required IconData icone,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        isActive ? C.accentA08 : C.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? C.accentA20 : C.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icone, color: isActive ? C.accent : C.mid, size: 14),
            const SizedBox(width: 7),
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
