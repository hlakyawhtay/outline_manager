import 'package:flutter/material.dart';
import '../../model/outline_server.dart';

class AddAccessKeyPage extends StatefulWidget {
  final OutlineServer server;
  const AddAccessKeyPage({super.key, required this.server});

  @override
  State<AddAccessKeyPage> createState() => _AddAccessKeyPageState();
}

class _AddAccessKeyPageState extends State<AddAccessKeyPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year}';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Access Key')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Key Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Expired Date:'),
                const SizedBox(width: 8),
                Text(
                  _selectedDate == null ? 'None' : _formatDate(_selectedDate),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 10),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _selectedTime?.hour ?? 0,
                          _selectedTime?.minute ?? 0,
                        );
                      });
                    }
                  },
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _selectedTime = null;
                      });
                    },
                  ),
              ],
            ),
            Row(
              children: [
                const Text('Expired Time:'),
                const SizedBox(width: 8),
                Text(
                  _selectedTime == null ? 'None' : _formatTime(_selectedTime),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedTime = picked;
                        if (_selectedDate != null) {
                          _selectedDate = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            picked.hour,
                            picked.minute,
                          );
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 42),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'name': _nameController.text,
                        'expiredDate': _selectedDate,
                        'note': _noteController.text,
                      });
                    },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
