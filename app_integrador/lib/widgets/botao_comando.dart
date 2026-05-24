// widget de botão de comando — usado na tela de controle
// exibe ícone + label e muda de cor qdo desativado (habilitado=false)
import 'package:flutter/material.dart';

class BotaoComando extends StatelessWidget {
  final String label;   // texto exibido no botão
  final String comando; // string q será enviada p/ a api (ex: "PAUSAR")
  final IconData icone;
  final Color cor;      // cor principal qdo habilitado
  final bool habilitado; // false = desativado durante requests
  final Future<void> Function(String comando) onPressed; // callback ao tocar

  const BotaoComando({
    super.key,
    required this.label,
    required this.comando,
    required this.icone,
    required this.cor,
    required this.onPressed,
    this.habilitado = true, // padrão: habilitado
  });

  @override
  Widget build(BuildContext context) {
    // qdo desabilitado usa cinza, senão usa a cor passada
    final activeColor = habilitado ? cor : const Color(0xFFAEAEB2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // sombra preta 4% opac — sem cor de destaque
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // transparent p/ o inkwell aparecer corretamente
        child: InkWell(
          // só ativa o toque se habilitado
          onTap: habilitado ? () => onPressed(comando) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              // mainAxisAlignment.center centraliza o conteúdo verticalmente no card
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // mini container colorido atrás do ícone
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.12), // fundo 12% opac
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icone, size: 18, color: activeColor),
                ),
                const SizedBox(height: 10),
                // label do botão
                Text(
                  label,
                  style: TextStyle(
                    color: habilitado
                        ? const Color(0xFF1C1C1E) // escuro qdo ativo
                        : const Color(0xFF8E8E93), // cinza qdo desabilitado
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
