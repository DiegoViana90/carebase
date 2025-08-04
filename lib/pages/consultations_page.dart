import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carebase/utils/base_page_layout.dart';
import 'package:carebase/pages/schedule_consultation_modal.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  late int selectedYear;
  late int selectedMonth;

  final currentYear = DateTime.now().year;

  List<int> get years => List.generate(5, (i) => currentYear - i);

  final List<String> months = List.generate(
    12,
    (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
  }

  int daysInMonth(int year, int month) {
    final beginningNextMonth =
        (month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);
    return beginningNextMonth.subtract(const Duration(days: 1)).day;
  }

  void _openScheduleModal(DateTime date) {
    showDialog(
      context: context,
      builder: (_) => ScheduleConsultationModal(date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = daysInMonth(selectedYear, selectedMonth);

    return BasePageLayout(
      title: 'Consultas',
      showBackButton: false,
      child: Column(
        children: [
          // Filtros Mês e Ano
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
                    setState(() {
                      selectedMonth = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 24),
              DropdownButton<int>(
                value: selectedYear,
                items: years
                    .map(
                      (year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedYear = value;
                    });
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grade de dias
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: daysInMonth(selectedYear, selectedMonth),
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(selectedYear, selectedMonth, day);
                final dateStr = DateFormat('dd/MM/yy').format(date);

                return GestureDetector(
                  onTap: () => _openScheduleModal(date),
                  child: Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
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
                            dateStr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Center(
                            child: Icon(
                              Icons.event_note,
                              size: 32,
                              color: Colors.teal,
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
