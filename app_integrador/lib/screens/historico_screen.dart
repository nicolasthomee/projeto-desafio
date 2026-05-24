// tela de histórico — exibe os registros diários de produção
// mostra um gráfico de barras dos últimos 7 dias + lista de cards
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // lib de gráficos
import '../models/historico_model.dart';
import '../services/api_service.dart';

class HistoricoScreen extends StatefulWidget {
  final String token;
  const HistoricoScreen({super.key, required this.token});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<HistoricoModel> _historico = []; // lista de registros vinda da api
  bool    _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar(); // busca os dados assim q a tela abre
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
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF007AFF)));
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
                    color: Color(0x14FF3B30), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFF3B30), size: 40),
              ),
              const SizedBox(height: 16),
              Text(_erro!,
                  style: const TextStyle(color: Color(0xFF6C6C70)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _carregar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Tentar novamente'),
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
                    color: Color(0x1F007AFF), shape: BoxShape.circle),
                child: const Icon(Icons.history_rounded,
                    color: Color(0xFF007AFF), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum histórico encontrado.',
                style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Feche um expediente para gerar dados.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // estado 4: dados disponíveis — gráfico + lista
    return RefreshIndicator(
      color: const Color(0xFF007AFF),
      onRefresh: _carregar, // arrastar p/ baixo recarrega
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // padding extra embaixo p/ o conteúdo n ficar atrás da pill nav
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histórico',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // gráfico de barras dos últimos 7 dias
            _buildGrafico(),
            const SizedBox(height: 24),

            const Text(
              'Registros Diários',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            // mapeia cada item do histórico p/ um card
            ..._historico.map(_buildCard),
          ],
        ),
      ),
    );
  }

  // monta o gráfico de barras com gradiente azul
  Widget _buildGrafico() {
    // pega só os últimos 7 registros e inverte a ordem p/ exibir do mais antigo ao mais novo
    final dados = _historico.take(7).toList().reversed.toList();
    final maxVal = dados.map((e) => e.totalPecas).reduce((a, b) => a > b ? a : b);
    // guarda: se todos os valores forem 0, usa 10 como máximo p/ evitar divisão por zero
    final maxY   = maxVal == 0 ? 10.0 : maxVal * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peças por dia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
            letterSpacing: -0.2,
          ),
        ),
        const Text(
          'Últimos 7 dias',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          height: 210,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(), // limite superior do eixo y
              barGroups: dados.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key, // posição no eixo x
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.totalPecas.toDouble(), // altura da barra
                      // gradiente azul de baixo p/ cima
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                      ),
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7)), // só arredonda o topo
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                // labels no eixo inferior: data formatada "dd/mm"
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
                        child: Text(label,
                            style: const TextStyle(
                                color: Color(0xFFAEAEB2), fontSize: 10)),
                      );
                    },
                  ),
                ),
                // labels no eixo esquerdo: valores numéricos
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32, // espaço reservado p/ os números
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                          color: Color(0xFFAEAEB2), fontSize: 10),
                    ),
                  ),
                ),
                // oculta os títulos do topo e da direita (desnecessários)
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              // linhas de grade horizontais sutis
              gridData: const FlGridData(
                getDrawingHorizontalLine: _gridLine,
              ),
              borderData: FlBorderData(show: false), // sem borda ao redor do gráfico
            ),
          ),
        ),
      ],
    );
  }

  // estilo das linhas de grade do gráfico — cinza bem claro
  // precisa ser static pq é referenciada como const no FlGridData
  static FlLine _gridLine(double _) =>
      const FlLine(color: Color(0xFFF2F2F7), strokeWidth: 1);

  // card de um registro diário c/ data, peças, tempo parado e alertas
  Widget _buildCard(HistoricoModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // ícone de calendário à esquerda
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0x1F007AFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_today_rounded,
              color: Color(0xFF007AFF), size: 20),
        ),
        // data do expediente como título
        title: Text(
          item.data ?? 'Data não registrada',
          style: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        // resumo em uma linha: peças • tempo parado • alertas
        subtitle: Text(
          '${item.totalPecas} peças  •  ${item.tempoParadoFormatado} parado  •  ${item.totalAlertas} alertas',
          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
        ),
        // número de peças em destaque à direita
        trailing: Text(
          '${item.totalPecas}',
          style: const TextStyle(
            color: Color(0xFF007AFF),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
