import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outline_manager/src/providers/repository_provider.dart';

import '../model/access_keys.dart';
import '../model/outline_server.dart';
import '../providers/firebase_providers.dart';
import '../repository/firestore_repository.dart';
import '../view_model/server_dashboard_provider.dart';
import '../view_model/server_view_model.dart';
import 'access_key_detail.dart';
import 'access_keys_screen.dart';
import 'widgets/access_key_search_delegate.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  void _openAccessKeyDetail(
    BuildContext context,
    WidgetRef ref,
    OutlineServer server,
    AccessKey key,
  ) {
    final url = server.outlineManagementApiUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL missing for this user.')),
      );
      return;
    }
    ref.read(baseUrlProviderProvider.notifier).setupUrl(url);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccessKeyDetail(accessKey: key, server: server),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serverViewModelProvider);
    final dashboardAsync = ref.watch(serverDashboardProvider);
    final serverCache = serversAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <OutlineServer>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Servers"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Search users',
            onPressed: serverCache.isEmpty
                ? null
                : () async {
                    final selection =
                        await showSearch<AccessKeySearchSelection?>(
                          context: context,
                          delegate: AccessKeySearchDelegate(
                            firestoreRepository: ref.read(
                              firestoreRepositoryProvider,
                            ),
                            serverLookup: {
                              for (final server in serverCache)
                                server.serverId: server,
                            },
                          ),
                        );
                    if (selection == null) {
                      return;
                    }
                    _openAccessKeyDetail(
                      context,
                      ref,
                      selection.server,
                      selection.accessKey,
                    );
                  },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(firebaseAuthProvider).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: serversAsync.when(
        data: (servers) {
          if (servers.isEmpty) {
            return const Center(
              child: Text(
                'No servers added yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          final serverLookup = {
            for (final server in servers) server.serverId: server,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ExpiringMembersSection(
                statsAsync: dashboardAsync,
                serverLookup: serverLookup,
                onSelect: (server, key) =>
                    _openAccessKeyDetail(context, ref, server, key),
              ),
              const SizedBox(height: 16),
              _MissingExpirySection(
                statsAsync: dashboardAsync,
                serverLookup: serverLookup,
                onSelect: (server, key) =>
                    _openAccessKeyDetail(context, ref, server, key),
              ),
              const SizedBox(height: 16),
              _HighUsageSection(
                statsAsync: dashboardAsync,
                serverLookup: serverLookup,
                onSelect: (server, key) =>
                    _openAccessKeyDetail(context, ref, server, key),
              ),
              const SizedBox(height: 24),
              Text('Servers', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...servers.map((server) {
                final userCount = dashboardAsync.maybeWhen(
                  data: (data) => data.usersFor(server.serverId),
                  orElse: () => 0,
                );
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  child: ListTile(
                    title: Text(server.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Created: ${_formatTimestamp(server.createdTimestampMs)}',
                        ),
                        Text('Users: $userCount'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref
                          .read(baseUrlProviderProvider.notifier)
                          .setupUrl(server.outlineManagementApiUrl!);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AccessKeysScreen(server: server),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final urlController = TextEditingController();
          final result = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Server'),
              content: TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Management URL'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(urlController.text),
                  child: const Text('Add'),
                ),
              ],
            ),
          );
          if (result != null && result.isNotEmpty) {
            await ref.read(serverViewModelProvider.notifier).addServer(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExpiringMembersSection extends StatelessWidget {
  const _ExpiringMembersSection({
    required this.statsAsync,
    required this.serverLookup,
    required this.onSelect,
  });

  final AsyncValue<ServerDashboardData> statsAsync;
  final Map<String, OutlineServer> serverLookup;
  final void Function(OutlineServer server, AccessKey key) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expiring & Expired Users',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (data) {
                final expiringSoon = data.expiringAccessKeys;
                final expired = data.expiredAccessKeys;
                if (expiringSoon.isEmpty && expired.isEmpty) {
                  return Text(
                    'No upcoming or past expirations.',
                    style: theme.textTheme.bodyMedium,
                  );
                }

                List<Widget> buildSection(
                  List<AccessKey> keys,
                  String header, {
                  required bool isExpired,
                }) {
                  if (keys.isEmpty) return <Widget>[];
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        header,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isExpired
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...keys.map((key) {
                      final server = key.serverId != null
                          ? serverLookup[key.serverId!]
                          : null;
                      final serverName = server?.name ?? 'Unknown server';
                      final expiry = key.expiredDate;
                      final timelineLabel = expiry != null
                          ? (isExpired
                                ? 'Expired: ${_formatDate(expiry)}'
                                : 'Expires: ${_formatDate(expiry)}')
                          : 'No date set';
                      final countdown = expiry == null
                          ? 'N/A'
                          : (isExpired
                                ? _formatExpiredCountdown(expiry)
                                : _formatCountdown(expiry));
                      return Card(
                        color: isExpired ? Colors.red.shade50 : Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            key.name.isEmpty ? key.outlineId : key.name,
                            style: theme.textTheme.bodyLarge,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serverName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(timelineLabel),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                countdown,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isExpired
                                      ? theme.colorScheme.error
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: server == null
                              ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Server unavailable; refresh servers and try again.',
                                    ),
                                  ),
                                )
                              : () => onSelect(server, key),
                        ),
                      );
                    }),
                  ];
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...buildSection(
                      expiringSoon,
                      'Expiring within 2 days',
                      isExpired: false,
                    ),
                    if (expiringSoon.isNotEmpty && expired.isNotEmpty)
                      const SizedBox(height: 12),
                    ...buildSection(
                      expired,
                      'Already expired',
                      isExpired: true,
                    ),
                  ],
                );
              },
              loading: () => const _CalculatingState(
                message: 'Calculating expiring users...',
              ),
              error: (error, _) => Text(
                'Unable to load expiring users',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingExpirySection extends StatelessWidget {
  const _MissingExpirySection({
    required this.statsAsync,
    required this.serverLookup,
    required this.onSelect,
  });

  final AsyncValue<ServerDashboardData> statsAsync;
  final Map<String, OutlineServer> serverLookup;
  final void Function(OutlineServer server, AccessKey key) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Users Missing Expiration Dates',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (data) {
                final missing = data.missingExpiryAccessKeys;
                if (missing.isEmpty) {
                  return Text(
                    'All users have expiration dates set.',
                    style: theme.textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: missing.map((key) {
                    final server = key.serverId != null
                        ? serverLookup[key.serverId!]
                        : null;
                    return Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          Icons.schedule_outlined,
                          color: Colors.orange.shade800,
                        ),
                        title: Text(
                          key.name.isEmpty ? key.outlineId : key.name,
                          style: theme.textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          server != null
                              ? '${server.name} · Add an expiration date'
                              : 'Server unavailable',
                        ),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: server == null
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Server unavailable; refresh servers and try again.',
                                  ),
                                ),
                              )
                            : () => onSelect(server, key),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const _CalculatingState(
                message: 'Calculating users without expiration dates...',
              ),
              error: (error, _) => Text(
                'Unable to load missing expirations',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighUsageSection extends StatelessWidget {
  const _HighUsageSection({
    required this.statsAsync,
    required this.serverLookup,
    required this.onSelect,
  });

  final AsyncValue<ServerDashboardData> statsAsync;
  final Map<String, OutlineServer> serverLookup;
  final void Function(OutlineServer server, AccessKey key) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('High Usage Users', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (data) {
                final heavyUsers = data.highUsageAccessKeys;
                if (heavyUsers.isEmpty) {
                  return Text(
                    'No users above 80% usage.',
                    style: theme.textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: heavyUsers.map((key) {
                    final server = key.serverId != null
                        ? serverLookup[key.serverId!]
                        : null;
                    final ratio = _usageRatioForKey(key);
                    final percentLabel = _formatUsagePercent(ratio);
                    final usageLabel = _usageDisplayForKey(key);
                    final color = _usageColorForRatio(ratio);
                    return Card(
                      color: Colors.blueGrey.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade100,
                          child: Icon(
                            Icons.data_usage,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                        title: Text(
                          key.name.isEmpty ? key.outlineId : key.name,
                          style: theme.textTheme.bodyLarge,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server?.name ?? 'Unknown server',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(usageLabel),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                percentLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: ratio.isFinite
                                    ? ratio.clamp(0.0, 1.0)
                                    : 1.0,
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: server == null
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Server unavailable; refresh servers and try again.',
                                  ),
                                ),
                              )
                            : () => onSelect(server, key),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const _CalculatingState(
                message: 'Scanning for high usage...',
              ),
              error: (error, _) => Text(
                'Unable to load usage data',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatingState extends StatelessWidget {
  const _CalculatingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LinearProgressIndicator(
            minHeight: 6,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
          ),
          const SizedBox(height: 8),
          Text(message, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _formatTimestamp(int timestampMs) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
  return _formatDate(date);
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String _formatCountdown(DateTime expiry) {
  final now = DateTime.now();
  final diff = expiry.difference(now);
  if (diff.isNegative) {
    return 'Expired';
  }
  final days = diff.inDays;
  final hours = diff.inHours.remainder(24);
  if (days > 0) {
    return '${days}d ${hours}h left';
  }
  final minutes = diff.inMinutes.remainder(60);
  return hours > 0 ? '${hours}h ${minutes}m left' : '${minutes}m left';
}

String _formatExpiredCountdown(DateTime expiry) {
  final now = DateTime.now();
  final diff = now.difference(expiry);
  if (diff.inDays > 0) {
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    return '${days}d ${hours}h ago';
  }
  final hours = diff.inHours;
  if (hours > 0) {
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}h ${minutes}m ago';
  }
  final minutes = diff.inMinutes;
  if (minutes > 0) {
    return '${minutes}m ago';
  }
  return 'Just now';
}

const int _defaultDataLimitBytes = 100 * 1000 * 1000 * 1000; // 100 GB

String _usageDisplayForKey(AccessKey key) {
  final usedBytes = key.bytesTransferred;
  if (usedBytes == null) {
    return 'Usage data unavailable';
  }
  final limitBytes = _resolveDataLimitBytes(key.dataLimit?.bytes);
  final used = _formatBytesDecimal(usedBytes);
  final limit = _formatBytesDecimal(limitBytes);
  return '$used / $limit';
}

double _usageRatioForKey(AccessKey key) {
  final usedBytes = key.bytesTransferred;
  if (usedBytes == null) return 0;
  final limitBytes = _resolveDataLimitBytes(key.dataLimit?.bytes);
  if (limitBytes <= 0) return 0;
  return usedBytes / limitBytes;
}

Color _usageColorForRatio(double ratio) {
  if (ratio < 0.8) {
    return Colors.green.shade700;
  }
  if (ratio < 0.95) {
    return Colors.orange.shade700;
  }
  return Colors.red.shade700;
}

String _formatUsagePercent(double ratio) {
  final percent = (ratio * 100).clamp(0, 999);
  final decimals = percent >= 100 ? 0 : 1;
  return '${percent.toStringAsFixed(decimals)}%';
}

int _resolveDataLimitBytes(int? limitBytes) {
  if (limitBytes == null || limitBytes <= 0) {
    return _defaultDataLimitBytes;
  }
  return limitBytes;
}

String _formatBytesDecimal(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  const base = 1000;
  var exponent = (log(bytes) / log(base)).floor();
  if (exponent >= suffixes.length) {
    exponent = suffixes.length - 1;
  }
  final size = bytes / pow(base, exponent);
  final decimals = exponent == 0 ? 0 : 1;
  return '${size.toStringAsFixed(decimals)} ${suffixes[exponent]}';
}
