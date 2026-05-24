// tela de controle remoto — envia comandos ao esp32 via api → mqtt
// cada botão chama _enviarComando() c/ o nome do comando correspondente
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/botao_comando.dart';

class ControleScreen extends StatefulWidget {
  final String token; // jwt necessário p/ autenticar o request
  const ControleScreen({super.key, required this.token});

  @override
  State<ControleScreen> createState() => _ControleScreenState();
}

class _ControleScreenState extends State<ControleScreen> {
  bool _enviando    = false; // bloqueia todos os botões durante o request
  String? _feedback;         // mensagem de sucesso ou erro exibida ao usuário
  bool _feedbackSucesso = true; // true = verde, false = vermelho

  // envia o comando p/ a api e atualiza o feedback na tela
  Future<void> _enviarComando(String comando) async {
    setState(() { _enviando = true; _feedback = null; });
    try {
      await ApiService.enviarComando(widget.token, comando);
      if (!mounted) return; // verifica se o widget ainda existe
      setState(() {
        _feedback = 'Comando "$comando" enviado com sucesso';
        _feedbackSucesso = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // remove o prefixo "Exception: " q o dart adiciona automaticamente
        _feedback = 'Erro: ${e.toString().replaceFirst('Exception: ', '')}';
        _feedbackSucesso = false;
      });
    } finally {
      // sempre reativa os botões ao terminar, mesmo se deu erro
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // padding extra embaixo p/ o conteúdo n ficar atrás da pill nav
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Controle Remoto',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Envie comandos ao ESP32 via MQTT',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          ),
          const SizedBox(height: 16),

          // banner de feedback — aparece após enviar um comando
          // verde p/ sucesso, vermelho p/ erro
          if (_feedback != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _feedbackSucesso
                    ? const Color(0x1434C759) // verde 8% opac
                    : const Color(0x14FF3B30), // vermelho 8% opac
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _feedbackSucesso
                      ? const Color(0x4034C759)
                      : const Color(0x40FF3B30),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _feedbackSucesso
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: _feedbackSucesso
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _feedback!,
                      style: TextStyle(
                        color: _feedbackSucesso
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // spinner centralizado qdo aguardando resposta da api
          if (_enviando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF007AFF)),
              ),
            ),

          // ── seção produção ─────────────────────────────────────────────

          _buildSectionHeader(
            title: 'Produção',
            icon: Icons.factory_outlined,
            color: const Color(0xFF007AFF),
          ),
          const SizedBox(height: 10),
          // grid 2 colunas c/ botões quadrados (childAspectRatio: 1.6)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true, // o grid ocupa só o espaço necessário
            physics: const NeverScrollableScrollPhysics(), // scroll só no pai
            padding: EdgeInsets.zero, // remove padding interno padrão do gridview
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6, // largura/altura = 1.6 → retângulo deitado
            children: [
              BotaoComando(
                label: 'Pausar Linha',
                comando: 'PAUSAR',
                icone: Icons.pause_circle_outline_rounded,
                cor: const Color(0xFFFF9500), // laranja
                habilitado: !_enviando, // desativa enquanto aguarda resposta
                onPressed: _enviarComando,
              ),
              BotaoComando(
                label: 'Retomar Linha',
                comando: 'RETOMAR',
                icone: Icons.play_circle_outline_rounded,
                cor: const Color(0xFF34C759), // verde
                habilitado: !_enviando,
                onPressed: _enviarComando,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── seção alertas ──────────────────────────────────────────────

          _buildSectionHeader(
            title: 'Alertas',
            icon: Icons.notifications_outlined,
            color: const Color(0xFFFF9500),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              BotaoComando(
                label: 'Silenciar',
                comando: 'SILENCIAR',
                icone: Icons.notifications_off_outlined,
                cor: const Color(0xFF007AFF),
                habilitado: !_enviando,
                onPressed: _enviarComando,
              ),
              BotaoComando(
                label: 'Reset Contador',
                comando: 'RESET',
                icone: Icons.refresh_rounded,
                cor: const Color(0xFFAF52DE), // roxo
                habilitado: !_enviando,
                onPressed: _enviarComando,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── seção expediente ───────────────────────────────────────────

          _buildSectionHeader(
            title: 'Expediente',
            icon: Icons.schedule_outlined,
            color: const Color(0xFFFF3B30),
          ),
          const SizedBox(height: 10),
          // botão de fechar expediente como item de lista largo (n no grid)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _enviando ? null : _confirmarFecharDia, // exige confirmação
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      // ícone no círculo vermelho
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFF3B30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            size: 20, color: Color(0xFFFF3B30)),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fechar Expediente',
                              style: TextStyle(
                                color: Color(0xFFFF3B30),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Salva o resumo do dia no banco',
                              style: TextStyle(
                                  color: Color(0xFF8E8E93), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // seta indicando q é clicável
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFAEAEB2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // monta o cabeçalho de cada seção c/ ícone colorido + título
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        // mini container colorido atrás do ícone
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10), // 10% opac da cor da seção
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // abre um dialog de confirmação antes de fechar o expediente
  // evita q o usuário acione por acidente — ação irreversível
  Future<void> _confirmarFecharDia() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Fechar Expediente',
          style: TextStyle(
              color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Isso encerrará o expediente atual e salvará o resumo do dia. Continuar?',
          style: TextStyle(color: Color(0xFF6C6C70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // retorna false = cancelou
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF007AFF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // retorna true = confirmou
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    // só envia o comando se o usuário confirmou
    if (confirmar == true) await _enviarComando('FECHAR_DIA');
  }
}
