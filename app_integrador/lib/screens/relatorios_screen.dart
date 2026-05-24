// tela de relatórios — exibe estatísticas agregadas do período selecionado
// permite filtrar por data de início e fim; sem filtro mostra tudo
import 'package:flutter/material.dart';
import '../models/relatorio_model.dart';
import '../services/api_service.dart';
import '../widgets/status_card.dart';

class RelatoriosScreen extends StatefulWidget {
  final String token;
  const RelatoriosScreen({super.key, required this.token});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  RelatorioModel? _relatorio; // dados do relatório vindos da api
  bool    _carregando = true;
  String? _erro;
  String? _dataInicio; // filtro de data início no formato "yyyy-MM-dd"
  String? _dataFim;    // filtro de data fim no formato "yyyy-MM-dd"

  @override
  void initState() {
    super.initState();
    _carregar(); // carrega ao abrir a tela, s/ filtros
  }

  // busca o relatório na api c/ os filtros de data atuais
  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final dados = await ApiService.getRelatorio(
        widget.token,
        dataInicio: _dataInicio, // null = sem filtro
        dataFim: _dataFim,
      );
      setState(() => _relatorio = dados);
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _carregando = false);
    }
  }

  // abre o seletor de data nativo do flutter
  // isInicio=true atualiza _dataInicio, false atualiza _dataFim
  Future<void> _selecionarData({required bool isInicio}) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024), // data mínima selecionável
      lastDate: DateTime.now(),  // n permite selecionar datas futuras
      // aplica o tema azul apple no date picker
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF007AFF)),
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

  // remove os dois filtros e recarrega tudo
  void _limparFiltros() {
    setState(() { _dataInicio = null; _dataFim = null; });
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // padding extra embaixo p/ n ficar atrás da pill nav
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relatórios',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // ── filtros de data ──────────────────────────────────────────────

          Row(
            children: [
              // botão de data início
              Expanded(
                child: _botaoData(
                  label: _dataInicio ?? 'Data início',
                  icone: Icons.calendar_today_rounded,
                  isActive: _dataInicio != null, // azul qdo tem valor, cinza qdo vazio
                  onTap: () => _selecionarData(isInicio: true),
                ),
              ),
              const SizedBox(width: 10),
              // botão de data fim
              Expanded(
                child: _botaoData(
                  label: _dataFim ?? 'Data fim',
                  icone: Icons.calendar_month_rounded,
                  isActive: _dataFim != null,
                  onTap: () => _selecionarData(isInicio: false),
                ),
              ),
              // botão de limpar filtros — só aparece se algum filtro ativo
              if (_dataInicio != null || _dataFim != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _limparFiltros,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x14FF3B30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Color(0xFFFF3B30), size: 18),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ── estados da tela ──────────────────────────────────────────────

          if (_carregando)
            const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF007AFF)))
          else if (_erro != null)
            Center(
              child: Column(
                children: [
                  Text(_erro!,
                      style: const TextStyle(color: Color(0xFFFF3B30)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
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
            )
          else if (_relatorio != null)
            _buildConteudo(_relatorio!), // exibe o relatório qdo disponível
        ],
      ),
    );
  }

  // conteúdo principal: badge do período + 4 cards + card de tempo médio
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
                    color: Color(0x148E8E93), shape: BoxShape.circle),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF8E8E93), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum dado para o período.',
                style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tente selecionar um período diferente.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // badge azul mostrando quantos dias foram analisados
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x1F007AFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.date_range_rounded,
                  color: Color(0xFF007AFF), size: 16),
              const SizedBox(width: 8),
              Text(
                // pluraliza corretamente: "1 dia analisado" / "3 dias analisados"
                '${r.totalDias} dia${r.totalDias > 1 ? 's' : ''} analisado${r.totalDias > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 cards de métricas em grid 2x2
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero, // remove o padding interno padrão do gridview
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0, // cards quadrados
          children: [
            StatusCard(
              titulo: 'MÉDIA DE PEÇAS',
              valor: r.mediaPecas.toStringAsFixed(1), // ex: "42.3"
              icone: Icons.show_chart_rounded,
              cor: const Color(0xFF007AFF),
            ),
            StatusCard(
              titulo: 'MÁXIMO',
              valor: r.maximoPecas.toString(),
              icone: Icons.arrow_upward_rounded,
              cor: const Color(0xFF34C759), // verde
            ),
            StatusCard(
              titulo: 'MÍNIMO',
              valor: r.minimoPecas.toString(),
              icone: Icons.arrow_downward_rounded,
              cor: const Color(0xFFFF9500), // laranja
            ),
            StatusCard(
              titulo: 'ALERTAS',
              valor: r.totalAlertas.toString(),
              icone: Icons.warning_amber_rounded,
              cor: const Color(0xFFFF3B30), // vermelho
            ),
          ],
        ),
        const SizedBox(height: 12),

        // card separado p/ o tempo médio parado — c/ destaque roxo
        Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ícone roxo
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAF52DE).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_off_rounded,
                      color: Color(0xFFAF52DE), size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tempo médio parado',
                      style: TextStyle(
                          color: Color(0xFF6C6C70), fontSize: 13),
                    ),
                    Text(
                      // arredonda p/ inteiro e adiciona "s por dia"
                      '${r.mediaTempoParadoSeg.toStringAsFixed(0)}s por dia',
                      style: const TextStyle(
                        color: Color(0xFFAF52DE),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // botão de seleção de data — muda de aparência qdo tem valor (isActive=true)
  Widget _botaoData({
    required String label,
    required IconData icone,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          // fundo azul claro qdo ativo, branco qdo inativo
          color: isActive ? const Color(0x1F007AFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0x4D007AFF)
                : const Color(0x66C6C6C8),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icone,
              color: isActive
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF8E8E93),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF007AFF)
                      : const Color(0xFF6C6C70),
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis, // corta c/ "..." se o texto for longo
              ),
            ),
          ],
        ),
      ),
    );
  }
}
