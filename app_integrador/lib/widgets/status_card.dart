// card de métrica reutilizável — usado no dashboard e nos relatórios
// dark industrial: ícone accent monocromático, número grande em JetBrains Mono
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  final String titulo;    // rótulo descritivo (ex: "PEÇAS PRODUZIDAS")
  final String valor;     // número / valor principal (ex: "142")
  final String? subtitulo;// linha extra opcional abaixo do título
  final IconData icone;
  // cor recebida p/ compatibilidade c/ chamadas existentes — ignorada no dark theme
  // td usa accent (ciano) p/ manter a regra das 3 cores
  // ignore: unused_field
  final Color? cor;

  const StatusCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.subtitulo,
    required this.icone,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // card escuro c/ borda border — s/ sombra (combina c/ o fundo dark)
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: C.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min, // ocupa só o espaço necessário
        children: [
          // ícone monocromático em accent — sem container colorido
          Icon(icone, color: C.accent, size: 18),
          const SizedBox(height: 16),

          // valor principal — fonte JetBrains Mono, grande, destaque visual
          Text(valor, style: T.metricL),
          const SizedBox(height: 4),

          // rótulo descritivo — maiúsculo, pequeño, cor secundária
          Text(
            titulo,
            style:    T.sectionLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // subtítulo opcional — exibido só se passado
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(subtitulo!, style: T.small),
          ],
        ],
      ),
    );
  }
}
