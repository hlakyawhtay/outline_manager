import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/access_keys.dart';
import '../model/outline_server.dart';
import '../view_model/access_key_view_model.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class AccessKeyDetail extends ConsumerWidget {
  final AccessKey accessKey;
  final OutlineServer server;
  const AccessKeyDetail({
    super.key,
    required this.accessKey,
    required this.server,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessKeysAsync = ref.watch(accessKeyViewModelProvider(server));
    final currentKey = accessKeysAsync.maybeWhen(
      data: (keys) => keys.firstWhere(
        (key) => key.id == accessKey.id,
        orElse: () => accessKey,
      ),
      orElse: () => accessKey,
    );

    int _dataLimitBytes(AccessKey key) {
      return key.dataLimit?.bytes ?? 0;
    }

    double totalDataLimitGb(AccessKey key) {
      const double bytesPerGbDecimal = 1000 * 1000 * 1000;
      final limitBytes = _dataLimitBytes(key);
      if (limitBytes == 0) return 0;
      return limitBytes / bytesPerGbDecimal;
    }

    String limitLabel(AccessKey key) {
      final limitBytes = _dataLimitBytes(key);
      if (limitBytes <= 0) return 'Unlimited';
      return '${totalDataLimitGb(key).toStringAsFixed(0)} GB';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Access Key Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Name'),
              subtitle: Text(currentKey.name),
            ),
            ListTile(
              title: const Text('Expired Date'),
              subtitle: Text(
                currentKey.expiredDate != null
                    ? DateFormat('MMM-dd yyyy').format(currentKey.expiredDate!)
                    : 'None',
              ),
            ),
            ListTile(
              title: const Text('Day Left'),
              subtitle: Text(_calculateDaysLeft(currentKey.expiredDate)),
            ),
            ListTile(
              title: const Text('Note'),
              subtitle: Text(
                (currentKey.note == null || currentKey.note!.isEmpty)
                    ? 'None'
                    : currentKey.note!,
              ),
            ),

            ListTile(
              title: const Text('Usage'),
              subtitle: Text(
                "${_formatBytes(currentKey.bytesTransferred)}/${limitLabel(currentKey)}",
              ),
              trailing: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  onTap: () async {
                    await _handleUpdateDataLimit(context, ref, currentKey);
                  },
                  child: Icon(
                    Icons.data_usage,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ),
            ),

            ListTile(
              title: const Text('Access Key'),
              subtitle: SelectableText(currentKey.accessUrl),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: currentKey.accessUrl),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Access key copied to clipboard!'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red.shade600),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade600,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Access Key'),
                        content: const Text(
                          'Are you sure you want to delete this access key?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(accessKeyViewModelProvider(server).notifier)
                          .deleteAccessKey(currentKey.outlineId);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Update'),
                  onPressed: () async {
                    await _showUpdateDialog(context, ref, currentKey);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDaysLeft(DateTime? expiredDate) {
    if (expiredDate == null) return '-';
    final now = DateTime.now();
    final difference = expiredDate.difference(now);
    return difference.inDays.toString();
  }

  Future<void> _handleUpdateDataLimit(
    BuildContext context,
    WidgetRef ref,
    AccessKey key,
  ) async {
    final dialogResult = await _showDataLimitDialog(context, key);
    if (dialogResult == null) return;
    final dataLimit = dialogResult.bytes != null
        ? DataLimit(bytes: dialogResult.bytes!)
        : null;
    try {
      final result = await ref
          .read(accessKeyViewModelProvider(server).notifier)
          .updateAccessKeyDataLimit(
            server: server,
            accessKeyId: key.outlineId,
            dataLimit: dataLimit,
          );
      if (result && context.mounted) {
        final limitLabel = dataLimit == null
            ? 'Data limit removed'
            : 'Data limit updated to '
                  '${(dataLimit.bytes / (1000 * 1000 * 1000)).toStringAsFixed(2)} GB';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(limitLabel)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update data limit: $e')),
        );
      }
    }
  }

  Future<({int? bytes})?> _showDataLimitDialog(
    BuildContext context,
    AccessKey key,
  ) async {
    const double bytesPerGbDecimal = 1000 * 1000 * 1000;
    final controller = TextEditingController(
      text: key.dataLimit != null && key.dataLimit!.bytes > 0
          ? (key.dataLimit!.bytes / bytesPerGbDecimal).toStringAsFixed(2)
          : '',
    );
    String? errorText;
    final result = await showDialog<({int? bytes})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Data Limit (GB)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Total data limit (GB)',
                  helperText: 'Leave blank and tap Unlimited to remove',
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop((bytes: null)),
              child: const Text('Unlimited'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                final parsed = double.tryParse(text);
                if (parsed == null || parsed <= 0) {
                  setState(() {
                    errorText = 'Enter a positive number';
                  });
                  return;
                }
                final bytes = (parsed * bytesPerGbDecimal).round();
                Navigator.of(context).pop((bytes: bytes));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    AccessKey key,
  ) async {
    final nameController = TextEditingController(text: key.name);
    final noteController = TextEditingController(text: key.note ?? '');
    DateTime? selectedDate = key.expiredDate;
    TimeOfDay? selectedTime = selectedDate != null
        ? TimeOfDay.fromDateTime(selectedDate)
        : null;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Access Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Key Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Expired Date:'),
                  const SizedBox(width: 8),
                  Text(
                    selectedDate == null ? 'None' : _formatDate(selectedDate),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            selectedTime?.hour ?? 0,
                            selectedTime?.minute ?? 0,
                          );
                        });
                      }
                    },
                  ),
                  if (selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          selectedDate = null;
                          selectedTime = null;
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
                    selectedTime == null ? 'None' : _formatTime(selectedTime),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                          if (selectedDate != null) {
                            selectedDate = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'name': nameController.text,
                'expiredDate': selectedDate,
                'note': noteController.text,
              }),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (result != null && (result['name'] as String).isNotEmpty) {
      await ref
          .read(accessKeyViewModelProvider(server).notifier)
          .updateAccessKey(
            key.outlineId,
            name: result['name'],
            expiredDate: result['expiredDate'],
            note: result['note'],
            noteProvided: true,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Access key updated!')));
      }
    }
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

  String _formatBytes(int? bytes, [int decimals = 2]) {
    if (bytes == null || bytes <= 0) return "0 B";
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    int i = (bytes == 0) ? 0 : (log(bytes) / log(1024)).floor();
    double size = bytes / (1 << (10 * i));
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }
}
