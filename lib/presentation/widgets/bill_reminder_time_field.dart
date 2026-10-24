import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillReminderTimeField extends StatelessWidget {
  final DateTime dueDate;
  final int daysBefore;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;
  const BillReminderTimeField({
    super.key,
    required this.dueDate,
    required this.daysBefore,
    required this.time,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final date = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - daysBefore,
      time.hour,
      time.minute,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time),
          title: const Text('Reminder time'),
          trailing: Text(time.format(context)),
          onTap: () async {
            final selected = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (selected != null) onChanged(selected);
          },
        ),
        Text(
          'Around ${time.format(context)} on ${DateFormat.yMMMd().format(date)} (device local time).',
        ),
        const Text(
          'Delivery may be delayed by battery or notification settings.',
        ),
        if (!date.isAfter(DateTime.now()))
          const Text(
            'This reminder time has passed. A future due-day reminder will be used if available.',
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
