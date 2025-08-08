import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carebase/utils/base_page_layout.dart';
import 'package:carebase/pages/schedule_consultation_modal.dart';
import 'package:carebase/core/services/consultation_service.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  late int selectedYear;
  late int selectedMonth;
  final currentYear = DateTime.now().year;

  Map<String, List<Map<String, dynamic>>> consultationsByDate = {};
  bool isLoading = true;

  List<int> get years => List.generate(5, (i) => currentYear - i);

  final List<String> months = List.generate(
    12,
    (i) => DateFormat.MMMM('pt_BR').format(DateTime(0, i + 1)),
  );
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() => isLoading = true);

    try {
      final result = await ConsultationService.fetchAllConsultations();
      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (final c in result) {
        try {
          final startRaw = c['startDate'];
          final endRaw = c['endDate'];
          if (startRaw == null || endRaw == null) continue;

          final start = DateTime.parse(startRaw.toString()).toLocal();
          final end = DateTime.parse(endRaw.toString()).toLocal();
          final key = DateFormat('yyyy-MM-dd').format(start);
          final patientName = c['patientName'] ?? 'Indisponível';

          grouped.putIfAbsent(key, () => []).add({
            'start': start,
            'end': end,
            'patient': patientName,
            'consultationId': c['consultationId'],
            'titulo1': c['titulo1'],
            'titulo2': c['titulo2'],
            'titulo3': c['titulo3'],
            'texto1': c['texto1'],
            'texto2': c['texto2'],
            'texto3': c['texto3'],
            'status': c['status'], // 👈 ADICIONAR ISSO
          });
        } catch (e) {
          debugPrint('⚠️ Erro ao converter item: $e');
        }
      }
      setState(() => consultationsByDate = grouped);
    } catch (e) {
      debugPrint('⛔ Erro ao carregar consultas: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  int daysInMonth(int year, int month) {
    final nextMonth =
        month < 12 ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  void _openScheduleModal(DateTime date) async {
    final formattedKey = DateFormat('yyyy-MM-dd').format(date);
    final occupied = consultationsByDate[formattedKey] ?? [];

    final result = await showDialog(
      context: context,
      builder:
          (_) => ScheduleConsultationModal(date: date, occupiedSlots: occupied),
    );

    if (result == true) {
      await _loadConsultations();
    }
  }

  Color _getColorByConsultationCount(int count) {
    const maxConsultations = 10;
    if (count == 0) return Colors.green[100]!;

    final ratio = (count / maxConsultations).clamp(0.0, 1.0);
    if (ratio < 0.5) {
      return Color.lerp(Colors.green[300], Colors.yellow[300], ratio * 2)!;
    } else {
      return Color.lerp(
        Colors.yellow[300],
        Colors.red[300],
        (ratio - 0.5) * 2,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = daysInMonth(selectedYear, selectedMonth);

    return BasePageLayout(
      title: 'Consultas',
      showBackButton: false,
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(
                          12,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(months[index]),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedMonth = value);
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      DropdownButton<int>(
                        value: selectedYear,
                        items:
                            years
                                .map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedYear = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: totalDays,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final date = DateTime(selectedYear, selectedMonth, day);
                        final key = DateFormat('yyyy-MM-dd').format(date);
                        final count = consultationsByDate[key]?.length ?? 0;

                        return GestureDetector(
                          onTap: () => _openScheduleModal(date),
                          child: Card(
                            color: _getColorByConsultationCount(count),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yy').format(date),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.black
                                              : null,
                                    ),
                                  ),
                                  const Spacer(),
                                  Center(
                                    child: Icon(
                                      Icons.event_note,
                                      size: 32,
                                      color:
                                          count > 0 ? Colors.teal : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
