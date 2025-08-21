import 'package:carebase/core/services/consultation_service.dart';
import 'package:carebase/pages/view_consultation_modal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carebase/pages/confirm_consultation_modal.dart';
import 'package:carebase/pages/payment_method_dialog.dart' show PaymentLine;
import 'package:carebase/enums/payment_method.dart';
import 'package:carebase/ui/status_tag.dart';

class ScheduleConsultationModal extends StatefulWidget {
  final DateTime date;
  final List<Map<String, dynamic>> occupiedSlots;

  const ScheduleConsultationModal({
    super.key,
    required this.date,
    this.occupiedSlots = const [],
  });

  @override
  State<ScheduleConsultationModal> createState() =>
      _ScheduleConsultationModalState();
}

class _ScheduleConsultationModalState extends State<ScheduleConsultationModal> {
  List<TimeOfDay> availableTimes = [];
  List<TimeOfDay> selectedTimes = [];
  Map<String, Map<String, dynamic>> occupiedMap = {};

  final ScrollController _scrollController = ScrollController();

  // formatador de data do título
  final _day = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    _mapOccupiedSlots();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  void _generateTimeSlots() {
    final start = const TimeOfDay(hour: 6, minute: 0);
    final end = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay current = start;

    while (_compareTimes(current, end) <= 0) {
      availableTimes.add(current);
      current = _addMinutes(current, 30);
    }
  }

  void _mapOccupiedSlots() {
    for (final slot in widget.occupiedSlots) {
      final start = (slot['start'] as DateTime).toLocal();
      final end = (slot['end'] as DateTime).toLocal();
      final patient = slot['patient'] ?? 'Indisponível';
      final status = slot['status']; // 0 agendado, 1 compareceu, 2 não compareceu, 3 reagendado
      final consultationId = slot['consultationId'];

      DateTime current = start;
      while (!current.isAfter(end.subtract(const Duration(minutes: 1)))) {
        final t = TimeOfDay.fromDateTime(current);
        final key = _keyFromTime(t);
        occupiedMap[key] = {
          'patient': patient,
          'status': status,
          'consultationId': consultationId,
          'start': start,
          'end': end,
        };
        current = current.add(const Duration(minutes: 30));
      }
    }
  }

  String _keyFromTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  int _compareTimes(TimeOfDay a, TimeOfDay b) =>
      a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute;

  TimeOfDay _addMinutes(TimeOfDay time, int minutesToAdd) {
    final totalMinutes = time.hour * 60 + time.minute + minutesToAdd;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  void _scrollToCurrentTime() {
    final isToday = DateUtils.isSameDay(widget.date, DateTime.now());
    final targetIndex = isToday
        ? (() {
            final now = TimeOfDay.now();
            final idx = availableTimes.indexWhere((t) => _compareTimes(t, now) >= 0);
            return idx > 0 ? idx - 3 : 0;
          })()
        : 4;
    final offset = (targetIndex.clamp(0, availableTimes.length) * 50.0).toDouble();

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _toggleTimeSelection(TimeOfDay time) {
    setState(() {
      final isSelected = selectedTimes.contains(time);

      if (isSelected) {
        selectedTimes.remove(time);
        selectedTimes = _rebuildContiguousSelection();
      } else {
        if (selectedTimes.isEmpty) {
          selectedTimes.add(time);
        } else {
          selectedTimes.sort(_compareTimes);
          final first = selectedTimes.first;
          final last = selectedTimes.last;

          final prev = _addMinutes(first, -30);
          final next = _addMinutes(last, 30);

          if (_compareTimes(time, prev) == 0 || _compareTimes(time, next) == 0) {
            selectedTimes.add(time);
            selectedTimes.sort(_compareTimes);
          }
        }
      }
    });
  }

  List<TimeOfDay> _rebuildContiguousSelection() {
    if (selectedTimes.isEmpty) return [];

    selectedTimes.sort(_compareTimes);
    final List<TimeOfDay> contiguous = [selectedTimes.first];

    for (int i = 1; i < selectedTimes.length; i++) {
      final prev = contiguous.last;
      final current = selectedTimes[i];

      if (_compareTimes(current, _addMinutes(prev, 30)) == 0) {
        contiguous.add(current);
      } else {
        break;
      }
    }

    return contiguous;
  }

  bool _isSelectable(TimeOfDay time) {
    final key = _keyFromTime(time);
    if (occupiedMap.containsKey(key)) return false;

    if (selectedTimes.isEmpty) return true;

    selectedTimes.sort(_compareTimes);
    final first = selectedTimes.first;
    final last = selectedTimes.last;

    final prev = _addMinutes(first, -30);
    final next = _addMinutes(last, 30);

    return _compareTimes(time, prev) == 0 ||
        _compareTimes(time, next) == 0 ||
        selectedTimes.contains(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = _day.format(widget.date);

    return AlertDialog(
      title: Text('Selecionar horários - $formattedDate'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: availableTimes.length,
            itemBuilder: (context, index) {
              final time = availableTimes[index];
              final timeKey = _keyFromTime(time);
              final isSelected = selectedTimes.contains(time);
              final occupancy = occupiedMap[timeKey];
              final isOccupied = occupancy != null;
              final patientName = occupancy?['patient'] as String?;
              final status = occupancy?['status'] as int?;

              // Cores/estilos consistentes
              final st = statusStyle(context, status);

              final isEnabled = _isSelectable(time);

              final textColor = isOccupied
                  ? st.fg
                  : isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : isEnabled
                          ? theme.textTheme.bodyLarge?.color
                          : theme.disabledColor;

              final backgroundColor = isOccupied
                  ? st.bg
                  : isSelected
                      ? theme.colorScheme.primaryContainer.withOpacity(0.6)
                      : Colors.transparent;

              final borderColor = isOccupied
                  ? st.border.withOpacity(0.7)
                  : isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor;

              return GestureDetector(
                onTap: () async {
                  if (isOccupied) {
                    final slot = widget.occupiedSlots.firstWhere((s) {
                      final start = (s['start'] as DateTime).toLocal();
                      final end = (s['end'] as DateTime).toLocal();
                      final clickedDateTime = DateTime(
                        widget.date.year,
                        widget.date.month,
                        widget.date.day,
                        time.hour,
                        time.minute,
                      );
                      return !clickedDateTime.isBefore(start) &&
                          clickedDateTime.isBefore(end);
                    }, orElse: () => {});

                    if (slot.isNotEmpty) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final details =
                            await ConsultationService.fetchConsultationDetails(
                          slot['consultationId'],
                        );

                        Navigator.pop(context); // fecha loader

                        final paymentsRaw = (details?['payments'] as List?) ?? const [];
                        final initialLines = paymentsRaw.map<PaymentLine>((raw) {
                          final p = raw as Map<String, dynamic>;
                          final methodIdx = (p['method'] as num?)?.toInt() ?? 0;
                          final safeMethodIdx =
                              methodIdx.clamp(0, PaymentMethod.values.length - 1);
                          final installments = (p['installments'] as num?)?.toInt() ?? 1;
                          final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;

                          return PaymentLine(
                            method: PaymentMethod.values[safeMethodIdx],
                            installments: installments,
                            amount: amount,
                          );
                        }).toList();

                        final result = await showDialog<bool>(
                          context: context,
                          builder: (_) => ViewConsultationModal(
                            consultationId: slot['consultationId'],
                            patient: details?['patientName'] ?? 'Desconhecido',
                            start: slot['start'],
                            end: slot['end'],
                            titulo1: details?['titulo1'],
                            titulo2: details?['titulo2'],
                            titulo3: details?['titulo3'],
                            texto1: details?['texto1'],
                            texto2: details?['texto2'],
                            texto3: details?['texto3'],
                            amountPaid: (details?['totalPaid'] ?? 0).toDouble(),
                            statusIndex: details?['status'],
                            initialPayments: initialLines,
                          ),
                        );

                        if (result == true) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        Navigator.pop(context); // fecha loader
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao buscar detalhes: $e')),
                        );
                      }
                    }
                  } else if (isEnabled) {
                    _toggleTimeSelection(time);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(time),
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                      const SizedBox(width: 8),
                      if (isOccupied) ...[
                        statusIcon(status, color: st.fg, kind: StatusKind.attendance),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '- ${patientName ?? "Indisponível"}',
                            style: TextStyle(fontSize: 12, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Se preferir um chip ao invés de ícone+nome:
                        // const SizedBox(width: 6),
                        // StatusTag(status: status, kind: StatusKind.attendance, showIcon: true),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: selectedTimes.isEmpty
              ? null
              : () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => ConfirmConsultationModal(
                      selectedTimes: selectedTimes,
                      availableTimes: availableTimes,
                      date: widget.date,
                    ),
                  );
                  if (result == true) {
                    Navigator.pop(context, true);
                  }
                },
          icon: const Icon(Icons.add),
          label: const Text('Agendar'),
        ),
      ],
    );
  }
}
