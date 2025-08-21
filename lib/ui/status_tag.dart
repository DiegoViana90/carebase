import 'package:flutter/material.dart';

/// Use para escolher rótulos/ícones conforme o contexto.
enum StatusKind { consultation, attendance }

class StatusStyle {
  final Color bg, fg, border;
  const StatusStyle(this.bg, this.fg, this.border);
}

/// Cores FIXAS (iguais às que você usava antes)
StatusStyle statusStyle(BuildContext context, int? status) {
  switch (status) {
    case 1: // concluída / compareceu -> VERDE
      return StatusStyle(
        Colors.green,
        Colors.white,
        Colors.green.shade700,
      );
    case 2: // cancelada / não compareceu -> VERMELHO
      return StatusStyle(
        Colors.red,
        Colors.white,
        Colors.red.shade700,
      );
    case 3: // faltou / reagendado -> BLUE GREY
      return StatusStyle(
        Colors.blueGrey,
        Colors.white,
        Colors.blueGrey.shade700,
      );
    case 0: // agendada -> LARANJA
    default:
      return StatusStyle(
        Colors.orange,
        Colors.white,
        Colors.orange.shade700,
      );
  }
}

/// Texto do status.
String statusLabel(int? status, {StatusKind kind = StatusKind.consultation}) {
  switch (kind) {
    case StatusKind.consultation:
      switch (status) {
        case 0: return 'Agendada';
        case 1: return 'Concluída';
        case 2: return 'Cancelada';
        case 3: return 'Faltou';
        default: return '—';
      }
    case StatusKind.attendance:
      switch (status) {
        case 0: return 'Agendado';
        case 1: return 'Compareceu';
        case 2: return 'Não compareceu';
        case 3: return 'Reagendado';
        default: return '—';
      }
  }
}

/// Ícone do status.
Widget statusIcon(
  int? status, {
  required Color color,
  double size = 16,
  StatusKind kind = StatusKind.consultation,
}) {
  switch (status) {
    case 0: return Icon(Icons.event_note, size: size, color: color);
    case 1: return Icon(Icons.check_circle, size: size, color: color);
    case 2: return Icon(Icons.cancel, size: size, color: color);
    case 3:
      return Icon(
        kind == StatusKind.attendance ? Icons.refresh : Icons.report,
        size: size,
        color: color,
      );
    default: return const SizedBox.shrink();
  }
}

/// Chip pronto (cores/ícone/label).
class StatusTag extends StatelessWidget {
  final int? status;
  final StatusKind kind;
  final bool dense;
  final bool showIcon;
  final bool outlined;

  const StatusTag({
    super.key,
    required this.status,
    this.kind = StatusKind.consultation,
    this.dense = true,
    this.showIcon = false,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final st = statusStyle(context, status);
    return Chip(
      label: Text(
        statusLabel(status, kind: kind),
        style: TextStyle(color: st.fg, fontWeight: FontWeight.w600),
      ),
      avatar: showIcon ? statusIcon(status, color: st.fg, kind: kind) : null,
      backgroundColor: st.bg,
      shape: StadiumBorder(
        side: BorderSide(color: (outlined ? st.border : st.bg).withOpacity(0.6)),
      ),
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : null,
    );
  }
}
