import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carebase/pages/confirm_consultation_modal.dart';

class ScheduleConsultationModal extends StatefulWidget {
  final DateTime date;
  final List<Map<String, DateTime>> occupiedSlots;

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
  Set<String> occupiedSet = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    _mapOccupiedSlots();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  void _generateTimeSlots() {
    final start = TimeOfDay(hour: 6, minute: 0);
    final end = TimeOfDay(hour: 22, minute: 0);
    TimeOfDay current = start;

    while (_compareTimes(current, end) <= 0) {
      availableTimes.add(current);
      current = _addMinutes(current, 30);
    }
  }

  void _mapOccupiedSlots() {
    for (final slot in widget.occupiedSlots) {
      final start = DateTime.parse(slot['start']!.toString()).toLocal();
      final end = DateTime.parse(slot['end']!.toString()).toLocal();

      DateTime current = start;
      while (!current.isAfter(end.subtract(const Duration(minutes: 1)))) {
        final t = TimeOfDay.fromDateTime(current);
        final key = _keyFromTime(t);
        occupiedSet.add(key);
        current = current.add(const Duration(minutes: 30));
      }
    }

    for (final slot in widget.occupiedSlots) {
      debugPrint(
        '🧪 slot start: ${slot['start']} | type: ${slot['start'].runtimeType}',
      );
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
    final now = TimeOfDay.now();
    final closestIndex = availableTimes.indexWhere(
      (t) => _compareTimes(t, now) >= 0,
    );
    final targetIndex = closestIndex > 0 ? closestIndex - 3 : 0;
    final offset = targetIndex * 50.0;

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  String _formatTime(TimeOfDay time) {
    final dt = DateTime(0, 0, 0, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  void _toggleTimeSelection(TimeOfDay time) {
    setState(() {
      bool isSelected = selectedTimes.contains(time);

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

          if (_compareTimes(time, prev) == 0 ||
              _compareTimes(time, next) == 0) {
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
    List<TimeOfDay> contiguous = [selectedTimes.first];

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
    if (occupiedSet.contains(key)) return false;

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
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.date);

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
              final isOccupied = occupiedSet.contains(timeKey);
              final isEnabled = _isSelectable(time);

              final textColor =
                  isOccupied
                      ? Colors.red
                      : isSelected
                      ? Theme.of(context).colorScheme.primary
                      : isEnabled
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).disabledColor;

              final backgroundColor =
                  isOccupied
                      ? Colors.red[100]
                      : isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent;

              final borderColor =
                  isOccupied
                      ? Colors.red
                      : isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300;

              return GestureDetector(
                onTap: isEnabled ? () => _toggleTimeSelection(time) : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
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
          onPressed:
              selectedTimes.isEmpty
                  ? null
                  : () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => ConfirmConsultationModal(
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
