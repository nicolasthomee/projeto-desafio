// botão de comando industrial — usado na tela de controle
// visual: dark surface c/ borda + row (ícone | label) — estilo painel de controle
// qdo desabilitado: ícone e texto ficam em C.low (quase invisível)
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BotaoComando extends StatelessWidget {
  final String label;    // texto exibido no botão
  final String comando;  // string enviada p/ a api (ex: "PAUSAR")
  final IconData icone;
  // cor recebida p/ compatibilidade — ignorada: td usa accent no dark theme
  // ignore: unused_field
  final Color? cor;
  final bool habilitado; // false = desativa o toque durante requests
  final Future<void> Function(String comando) onPressed;

  const BotaoComando({
    super.key,
    required this.label,
    required this.comando,
    required this.icone,
    this.cor,
    required this.onPressed,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    // determina cores c/ base no estado habilitado/desabilitado
    final corIcone = habilitado ? C.accent : C.low;
    final corLabel = habilitado ? C.hi     : C.low;

    return Container(
      // fundo dark surface c/ borda border — aspecto de botão de controle real
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: C.border),
      ),
      child: Material(
        color: Colors.transparent, // transparent p/ o inkwell aparecer corretamente
        child: InkWell(
          onTap:           habilitado ? () => onPressed(comando) : null,
          borderRadius:    BorderRadius.circular(8),
          // ripple em accent sutil p/ feedback de toque
          splashColor:     C.accentA08,
          highlightColor:  C.accentA08,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // ícone monocromático — accent qdo ativo, low qdo inativo
                Icon(icone, size: 20, color: corIcone),
                const SizedBox(width: 12),
                // label — Space Grotesk, peso 600
                Expanded(
                  child: Text(
                    label,
                    style: T.body.copyWith(
                      color:      corLabel,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
