// tela de controle remoto — envia comandos ao esp32 via api → mqtt
// visual: seções c/ cabeçalho + linha divisória, botões industriais em grid
// lógica de envio e feedback: idêntica à versão anterior
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botao_comando.dart';

class ControleScreen extends StatefulWidget {
  final String token; // jwt p/ autenticar o request
  const ControleScreen({super.key, required this.token});

  @override
  State<ControleScreen> createState() => _ControleScreenState();
}

class _ControleScreenState extends State<ControleScreen> {
  bool    _enviando        = false; // bloqueia todos os botões durante o request
  String? _feedback;                // mensagem exibida após enviar o comando
  bool    _feedbackSucesso = true;  // true = accent (sucesso), false = accent (erro)

  // envia o comando p/ a api e atualiza o feedback na tela
  Future<void> _enviarComando(String comando) async {
    setState(() { _enviando = true; _feedback = null; });
    try {
      await ApiService.enviarComando(widget.token, comando);
      if (!mounted) return;
      setState(() {
        _feedback        = 'Comando "$comando" enviado';
        _feedbackSucesso = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedback        = 'Erro: ${e.toString().replaceFirst('Exception: ', '')}';
        _feedbackSucesso = false;
      });
    } finally {
      // sempre reativa os botões ao terminar, mesmo c/ erro
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

          // ── título da tela ────────────────────────────────────────────────
          Text('CONTROLE REMOTO', style: T.heading),
          const SizedBox(height: 4),
          Text('Envia comandos ao ESP32 via MQTT', style: T.bodySec),
          const SizedBox(height: 20),

          // ── banner de feedback ────────────────────────────────────────────
          // aparece após enviar um comando — usa accent p/ sucesso e erro
          // (mantém regra das 3 cores: sucesso/erro só diferem pelo ícone)
          if (_feedback != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                // fundo sutil accent p/ sucesso; um pouco mais intenso p/ erro
                color:        _feedbackSucesso ? C.accentA08 : C.accentA20,
                borderRadius: BorderRadius.circular(6),
                border:       Border.all(color: C.accentA20),
              ),
              child: Row(
                children: [
                  Icon(
                    // ícone diferencia sucesso de erro (cor é a mesma: accent)
                    _feedbackSucesso
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: C.accent,
                    size:  18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_feedback!,
                        style: T.bodySec.copyWith(color: C.accent)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // spinner centralizado qdo aguardando resp da api
          if (_enviando)
            const Padding(
              padding: EdgeInsets.all(16),
              child:   Center(
                child: CircularProgressIndicator(color: C.accent),
              ),
            ),

          // ── seção produção ────────────────────────────────────────────────
          _buildSectionHeader('PRODUÇÃO'),
          const SizedBox(height: 10),
          // grid 2 colunas — botões em row (ícone + label): estilo industrial
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap:     true,  // ocupa só o espaço necessário
            physics: const NeverScrollableScrollPhysics(), // scroll apenas no pai
            padding:           EdgeInsets.zero,
            crossAxisSpacing:  10,
            mainAxisSpacing:   10,
            childAspectRatio:  2.2, // retângulo deitado — mais denso q o card quadrado
            children: [
              BotaoComando(
                label:     'Pausar Linha',
                comando:   'PAUSAR',
                icone:     Icons.pause_circle_outline_rounded,
                habilitado: !_enviando,
                onPressed: _enviarComando,
              ),
              BotaoComando(
                label:     'Retomar Linha',
                comando:   'RETOMAR',
                icone:     Icons.play_circle_outline_rounded,
                habilitado: !_enviando,
                onPressed: _enviarComando,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── seção alertas ─────────────────────────────────────────────────
          _buildSectionHeader('ALERTAS'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap:     true,
            physics: const NeverScrollableScrollPhysics(),
            padding:          EdgeInsets.zero,
            crossAxisSpacing: 10,
            mainAxisSpacing:  10,
            childAspectRatio: 2.2,
            children: [
              BotaoComando(
                label:     'Silenciar',
                comando:   'SILENCIAR',
                icone:     Icons.notifications_off_outlined,
                habilitado: !_enviando,
                onPressed: _enviarComando,
              ),
              BotaoComando(
                label:     'Reset Contador',
                comando:   'RESET',
                icone:     Icons.refresh_rounded,
                habilitado: !_enviando,
                onPressed: _enviarComando,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── seção expediente ──────────────────────────────────────────────
          _buildSectionHeader('EXPEDIENTE'),
          const SizedBox(height: 10),

          // botão "fechar expediente" — largura total, destaque c/ borda accent
          // é o mais chamativo da tela: ação destrutiva e irreversível
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color:        C.surface,
              borderRadius: BorderRadius.circular(8),
              // borda accent plena = indicador de "ação crítica"
              border: Border.all(color: C.accentA20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:        _enviando ? null : _confirmarFecharDia,
                borderRadius: BorderRadius.circular(8),
                splashColor:  C.accentA08,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // ícone em accent — destaca da seção inteira
                      const Icon(Icons.logout_rounded,
                          size: 20, color: C.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FECHAR EXPEDIENTE',
                                style: T.body.copyWith(
                                  color:      C.accent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                )),
                            const SizedBox(height: 2),
                            Text('Salva o resumo do dia no banco',
                                style: T.small),
                          ],
                        ),
                      ),
                      // seta indicando q é clicável
                      const Icon(Icons.chevron_right_rounded, color: C.mid),
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

  // cabeçalho de seção: label + linha divisória à direita
  // ex: "PRODUÇÃO ───────────────────────────"
  Widget _buildSectionHeader(String titulo) {
    return Row(
      children: [
        Text(titulo, style: T.sectionLabel),
        const SizedBox(width: 10),
        const Expanded(child: Divider()), // linha divisória até a borda
      ],
    );
  }

  // dialog de confirmação antes de fechar expediente — ação irreversível
  Future<void> _confirmarFecharDia() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: C.border)),
        title: Text('FECHAR EXPEDIENTE',
            style: T.body.copyWith(
                color: C.hi, fontWeight: FontWeight.w700)),
        content: Text(
          'Isso encerrará o expediente atual e salvará o resumo do dia. Continuar?',
          style: T.bodySec,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          // botão de confirmação — accent background (ação primária destrutiva)
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero, // remove o minimumSize global
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
    // só envia o comando se o usuário confirmou
    if (confirmar == true) await _enviarComando('FECHAR_DIA');
  }
}
