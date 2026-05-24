// card de métrica — exibe um ícone colorido, um valor em destaque e um título
// usado no dashboard (peças produzidas, tempo parado) e tbm nos relatórios
import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String titulo;    // label descritivo em cima (ex: "PEÇAS PRODUZIDAS")
  final String valor;     // valor principal em destaque (ex: "42")
  final String? subtitulo; // linha extra opcional abaixo do título
  final IconData icone;
  final Color cor;        // cor do ícone e do fundo do ícone

  const StatusCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.subtitulo, // opcional — se n passar, n exibe
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // sombra bem suave
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ícone c/ fundo colorido semitransparente
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12), // 12% opac da cor do card
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: cor, size: 20),
            ),
            const SizedBox(height: 10),
            // valor principal — número grande em destaque
            Text(
              valor,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            // label descritivo em letras pequenas
            Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF6C6C70),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            // subtítulo opcional — exibido apenas se passado
            if (subtitulo != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitulo!,
                style: const TextStyle(
                  color: Color(0xFFAEAEB2),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
