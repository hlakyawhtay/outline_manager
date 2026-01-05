import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/access_keys.dart';
import '../model/outline_server.dart';
import '../repository/access_key_repository.dart';
import '../repository/firestore_repository.dart';

class ServerDashboardData {
  const ServerDashboardData({
    required this.userCounts,
    required this.expiringAccessKeys,
    required this.missingExpiryAccessKeys,
    required this.expiredAccessKeys,
    required this.highUsageAccessKeys,
  });

  final Map<String, int> userCounts;
  final List<AccessKey> expiringAccessKeys;
  final List<AccessKey> missingExpiryAccessKeys;
  final List<AccessKey> expiredAccessKeys;
  final List<AccessKey> highUsageAccessKeys;

  int usersFor(String? serverId) {
    if (serverId == null) return 0;
    return userCounts[serverId] ?? 0;
  }
}

final serverDashboardProvider = FutureProvider<ServerDashboardData>((
  ref,
) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final servers = await firestoreRepo.getServers();
  final now = DateTime.now();
  final cutoff = now.add(const Duration(days: 2));

  final counts = <String, int>{
    for (final server in servers) server.serverId: 0,
  };
  final expiring = <AccessKey>[];
  final missingExpiry = <AccessKey>[];
  final expired = <AccessKey>[];
  final highUsage = <AccessKey>[];

  for (final server in servers) {
    final keys = await _loadKeysForServer(server, firestoreRepo);
    counts[server.serverId] = keys.length;

    for (final key in keys) {
      final expiry = key.expiredDate;
      final isExpiringSoon =
          expiry != null && !expiry.isBefore(now) && !expiry.isAfter(cutoff);
      if (isExpiringSoon) {
        expiring.add(key);
      }
      if (expiry != null && expiry.isBefore(now)) {
        expired.add(key);
      }
      if (expiry == null) {
        missingExpiry.add(key);
      }

      final usageRatio = _usageRatio(key);
      if (usageRatio >= 0.8) {
        highUsage.add(key);
      }
    }
  }

  expiring.sort((a, b) {
    final aExpiry = a.expiredDate;
    final bExpiry = b.expiredDate;
    if (aExpiry == null && bExpiry == null) return 0;
    if (aExpiry == null) return 1;
    if (bExpiry == null) return -1;
    return aExpiry.compareTo(bExpiry);
  });

  missingExpiry.sort((a, b) {
    final serverCompare = (a.serverId ?? '').compareTo(b.serverId ?? '');
    if (serverCompare != 0) return serverCompare;
    return (a.name.isEmpty ? a.outlineId : a.name).compareTo(
      b.name.isEmpty ? b.outlineId : b.name,
    );
  });

  expired.sort((a, b) {
    final aExpiry = a.expiredDate;
    final bExpiry = b.expiredDate;
    if (aExpiry == null && bExpiry == null) return 0;
    if (aExpiry == null) return 1;
    if (bExpiry == null) return -1;
    return aExpiry.compareTo(bExpiry);
  });

  highUsage.sort((a, b) => _usageRatio(b).compareTo(_usageRatio(a)));

  return ServerDashboardData(
    userCounts: counts,
    expiringAccessKeys: expiring,
    missingExpiryAccessKeys: missingExpiry,
    expiredAccessKeys: expired,
    highUsageAccessKeys: highUsage,
  );
});

Future<List<AccessKey>> _loadKeysForServer(
  OutlineServer server,
  FirestoreRepository firestoreRepo,
) async {
  final localKeys = await firestoreRepo.getAccessKeys(
    serverId: server.serverId,
  );
  final managementUrl = server.outlineManagementApiUrl;
  if (managementUrl == null || managementUrl.isEmpty) {
    return localKeys;
  }
  try {
    final repo = _buildAccessKeyRepository(managementUrl);
    final remoteKeys = await repo.getAllAccessKeys();
    return _mergeRemoteWithLocal(
      remoteKeys: remoteKeys,
      localKeys: localKeys,
      server: server,
      firestoreRepo: firestoreRepo,
    );
  } catch (e, st) {
    log(
      'Failed to refresh access keys for ${server.serverId}: $e',
      stackTrace: st,
    );
    return localKeys;
  }
}

Future<List<AccessKey>> _mergeRemoteWithLocal({
  required List<AccessKey> remoteKeys,
  required List<AccessKey> localKeys,
  required OutlineServer server,
  required FirestoreRepository firestoreRepo,
}) async {
  final normalized = remoteKeys
      .map((key) => key.copyWith(serverId: server.serverId))
      .toList();
  final localKeyMap = {for (var key in localKeys) key.id: key};
  final remoteKeyIds = {for (var key in normalized) key.id};

  for (final key in normalized) {
    final local = localKeyMap[key.id];
    await firestoreRepo.upsertAccessKey(
      key.copyWith(expiredDate: local?.expiredDate),
    );
  }

  for (final localKey in localKeys) {
    if (!remoteKeyIds.contains(localKey.id)) {
      log('Removing orphaned key ${localKey.id} for ${server.serverId}');
      await firestoreRepo.deleteAccessKey(localKey.id);
    }
  }

  return normalized.map((key) {
    final local = localKeyMap[key.id];
    if (local != null && local.expiredDate != null) {
      return key.copyWith(expiredDate: local.expiredDate);
    }
    return key;
  }).toList();
}

AccessKeyRepository _buildAccessKeyRepository(String baseUrl) {
  final dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
  return AccessKeyRepository(dio: dio, baseUrl: baseUrl);
}

const int _defaultUsageLimitBytes = 100 * 1000 * 1000 * 1000; // 100 GB

double _usageRatio(AccessKey key) {
  final transferred = key.bytesTransferred;
  if (transferred == null) return 0;
  final limit = _resolveLimitBytes(key.dataLimit?.bytes);
  if (limit <= 0) return 0;
  return transferred / limit;
}

int _resolveLimitBytes(int? limitBytes) {
  if (limitBytes == null || limitBytes <= 0) {
    return _defaultUsageLimitBytes;
  }
  return limitBytes;
}
