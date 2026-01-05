import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';
import '../model/access_keys.dart';
import '../model/outline_server.dart';
import '../view_model/access_key_view_model.dart';
import 'widgets/add_access_key.dart';
import 'access_key_detail.dart';

class AccessKeysScreen extends ConsumerStatefulWidget {
  final OutlineServer server;
  const AccessKeysScreen({super.key, required this.server});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AccessKeysScreenState();
}

class _AccessKeysScreenState extends ConsumerState<AccessKeysScreen> {
  @override
  Widget build(BuildContext context) {
    final accessKeysAsync = ref.watch(
      accessKeyViewModelProvider(widget.server),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.server.name,
          maxLines: 2,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        ),
        actionsPadding: EdgeInsets.only(right: 22),

        actions: [
          InkWell(
            onTap: () async {
              final result = await Navigator.of(context)
                  .push<Map<String, dynamic>>(
                    MaterialPageRoute(
                      builder: (context) =>
                          AddAccessKeyPage(server: widget.server),
                    ),
                  );
              if (result != null && (result['name'] as String).isNotEmpty) {
                await ref
                    .read(accessKeyViewModelProvider(widget.server).notifier)
                    .addAccessKey(
                      result['name'],
                      expiredDate: result['expiredDate'],
                      note: result['note'],
                    );
              }
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: Colors.green.shade600),
            ),
          ),
        ],
      ),
      body: accessKeysAsync.when(
        data: (keys) {
          if (keys.isEmpty) {
            return const Center(child: Text('No access keys found.'));
          }
          final sortedKeys = [...keys]
            ..sort((a, b) {
              final aDate = a.expiredDate;
              final bDate = b.expiredDate;
              if (aDate == null && bDate == null) {
                return a.name.compareTo(b.name);
              }
              if (aDate == null) return 1; // nulls last
              if (bDate == null) return -1;
              return aDate.compareTo(bDate);
            });
          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final infoRows = _buildInfoRows(key);
              return Card(
                child: ListTile(
                  title: Text(key.name.isEmpty ? "Add New User" : key.name),
                  subtitle: infoRows.isEmpty
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: infoRows,
                        ),
                  // trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    if (key.accessUrl.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AccessKeyDetail(
                            accessKey: key,
                            server: widget.server,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => _buildShimmerList(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _calculateDaysLeft(DateTime expiredDate) {
    final now = DateTime.now();
    final difference = expiredDate.difference(now);
    return difference.inDays;
  }

  static const List<String> suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  static const int _defaultLimitBytes = 100 * 1000 * 1000 * 1000; // 100 GB

  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const base = 1000;
    int i = (log(bytes) / log(base)).floor();
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    final size = bytes / pow(base, i);
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  List<Widget> _buildInfoRows(AccessKey key) {
    final rows = <Widget>[];

    if (key.expiredDate != null) {
      rows.add(
        _infoRow('exp', DateFormat('MMM-dd yyyy').format(key.expiredDate!)),
      );

      final daysLeft = _calculateDaysLeft(key.expiredDate!);
      rows.add(
        _infoRow(
          'dayleft',
          _formatDayLeftLabel(daysLeft),
          valueColor: daysLeft < 0
              ? Colors.red.shade600
              : Colors.blueGrey.shade800,
        ),
      );
    }

    if (key.bytesTransferred != null) {
      final limitBytes = _resolveLimitBytes(key.dataLimit?.bytes);
      rows.add(
        _infoRow(
          'usage',
          _usageDisplay(key.bytesTransferred!, limitBytes),
          valueColor: _usageColor(key.bytesTransferred, limitBytes),
        ),
      );
    }

    if ((key.note ?? '').trim().isNotEmpty) {
      rows.add(
        _infoRow('note', key.note!.trim(), valueColor: Colors.teal.shade700),
      );
    }

    return rows;
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _usageDisplay(int usedBytes, int? limitBytes) {
    final used = _formatBytes(usedBytes);
    final effectiveLimit = _resolveLimitBytes(limitBytes);
    if (effectiveLimit <= 0) {
      return used;
    }
    final limit = _formatBytes(effectiveLimit);
    return '$used / $limit';
  }

  String _formatDayLeftLabel(int daysLeft) {
    if (daysLeft == 0) {
      return 'today';
    }
    final abs = daysLeft.abs();
    final unit = abs == 1 ? 'day' : 'days';
    if (daysLeft > 0) {
      return '$abs $unit';
    }
    return '$abs $unit overdue';
  }

  Color _usageColor(int? bytesTransferred, int? limitBytes) {
    if (bytesTransferred == null) {
      return Colors.deepPurple;
    }

    final effectiveLimit = _resolveLimitBytes(limitBytes);
    if (effectiveLimit <= 0) {
      return Colors.deepPurple;
    }

    final ratio = bytesTransferred / effectiveLimit;
    if (ratio < 0.8) {
      return Colors.green.shade700;
    }
    if (ratio < 0.95) {
      return Colors.orange.shade700;
    }
    return Colors.red.shade700;
  }

  int _resolveLimitBytes(int? limitBytes) {
    if (limitBytes == null || limitBytes <= 0) {
      return _defaultLimitBytes;
    }
    return limitBytes;
  }
}
