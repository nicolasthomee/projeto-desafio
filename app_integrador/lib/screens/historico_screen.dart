// tela de histórico — registros diários de produção
// gráfico de barras 7 dias + lista de cards compactos
// lógica de carregamento e pull-to-refresh: idêntica à versão anterior
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/historico_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HistoricoScreen extends StatefulWidget {
  final String token;
  const HistoricoScreen({super.key, required this.token});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<HistoricoModel> _historico = [];
  bool    _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar(); // busca os dados ao abrir a tela
  }

  // busca o histórico completo na api
  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final dados = await ApiService.getHistorico(widget.token);
      setState(() => _historico = dados);
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // estado 1: carregando
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: C.accent));
    }

    // estado 2: erro
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: C.accentA08, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded,
                    color: C.accent, size: 40),
              ),
              const SizedBox(height: 16),
              Text(_erro!, style: T.bodySec, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:   _carregar,
                child: const Text('TENTAR NOVAMENTE'),
              ),
            ],
          ),
        ),
      );
    }

    // estado 3: sem dados — nenhum expediente foi fechado ainda
    if (_historico.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: C.accentA08, shape: BoxShape.circle),
                child: const Icon(Icons.history_rounded,
                    color: C.accent, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Nenhum histórico encontrado.',
                  style: T.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Feche um expediente p/ gerar dados.',
                  style: T.bodySec, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // estado 4: dados disponíveis — gráfico + lista
    return RefreshIndicator(
      color:     C.accent,
      onRefresh: _carregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HISTÓRICO', style: T.heading),
            const SizedBox(height: 16),

            // gráfico de barras dos últimos 7 dias em accent
            _buildGrafico(),
            const SizedBox(height: 24),

            Text('REGISTROS DIÁRIOS', style: T.sectionLabel),
            const SizedBox(height: 10),

            // mapeia cada item do histórico p/ um card compacto
            ..._historico.map(_buildCard),
          ],
        ),
      ),
    );
  }

  // gráfico de barras — accent monocromático, fundo dark, grid em border
  Widget _buildGrafico() {
    // pega só os últimos 7 registros e inverte p/ exibir do mais antigo ao mais novo
    final dados  = _historico.take(7).toList().reversed.toList();
    final maxVal = dados.map((e) => e.totalPecas).reduce((a, b) => a > b ? a : b);
    // se td for 0, usa 10 p/ evitar divisão por zero no eixo y
    final maxY   = (maxVal == 0 ? 10.0 : maxVal * 1.25).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PEÇAS POR DIA', style: T.sectionLabel),
        const SizedBox(height: 4),
        Text('Últimos 7 dias', style: T.small),
        const SizedBox(height: 12),
        Container(
          height: 210,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          decoration: BoxDecoration(
            color:        C.surface,
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: C.border),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:      maxY,
              barGroups: dados.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY:   entry.value.totalPecas.toDouble(),
                      // cor única: accent — sem gradiente (regra das 3 cores)
                      color: C.accent,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)), // arredonda só o topo
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                // labels no eixo inferior: "dd/mm"
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= dados.length) return const SizedBox();
                      final data   = dados[idx].data ?? '';
                      final partes = data.split('-');
                      // converte "2024-05-20" → "20/05"
                      final label  = partes.length == 3
                          ? '${partes[2]}/${partes[1]}'
                          : data;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(label, style: T.small),
                      );
                    },
                  ),
                ),
                // labels no eixo esquerdo: valores numéricos
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) =>
                        Text(value.toInt().toString(), style: T.small),
                  ),
                ),
                // oculta topo e direita — desnecessários
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              // linhas de grade em border — sutis no dark
              gridData: const FlGridData(
                getDrawingHorizontalLine: _gridLine,
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  // linha de grade do gráfico — border color, espessura 1
  // static pq é referenciada como callback no FlGridData
  static FlLine _gridLine(double _) =>
      const FlLine(color: Color(0xFF30363D), strokeWidth: 1);

  // card de registro diário — compacto c/ data em destaque + métricas secundárias
  Widget _buildCard(HistoricoModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ícone de calendário em accent
            const Icon(Icons.calendar_today_rounded,
                color: C.accent, size: 18),
            const SizedBox(width: 14),

            // data e métricas secundárias
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // data do expediente — peso maior, cor primária
                  Text(
                    item.data ?? 'Data não registrada',
                    style: T.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  // métricas em linha: peças • tempo • alertas
                  Text(
                    '${item.totalPecas} peças  ·  '
                    '${item.tempoParadoFormatado} parado  ·  '
                    '${item.totalAlertas} alertas',
                    style: T.small,
                  ),
                ],
              ),
            ),

            // número de peças em destaque à direita — JetBrains Mono accent
            Text(
              '${item.totalPecas}',
              style: T.metricM,
            ),
          ],
        ),
      ),
    );
  }
}
