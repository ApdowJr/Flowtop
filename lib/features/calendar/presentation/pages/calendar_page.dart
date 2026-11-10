import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/core/theme/app_theme.dart';

/// Calendar view with daily/weekly toggles (table_calendar powered).
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text(AppStrings.calendar)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _format,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() { _selectedDay = selected; _focusedDay = focused; });
              },
              onFormatChanged: (format) => setState(() => _format = format),
              onPageChanged: (focused) => _focusedDay = focused,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(color: AppColors.surfaceVariant),
                formatButtonTextStyle: TextStyle(color: AppColors.primary),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a date to view tasks'))
                : Center(
                    child: Text('Tasks for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'),
                  ),
          ),
        ],
      ),
    );
  }
}
