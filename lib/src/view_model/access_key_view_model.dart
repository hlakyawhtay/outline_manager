import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/access_keys.dart';
import '../model/outline_server.dart';
import '../providers/repository_provider.dart';
import '../repository/access_key_repository.dart';
import '../repository/firestore_repository.dart';
import 'server_dashboard_provider.dart';

part 'access_key_view_model.g.dart';

@riverpod
class AccessKeyViewModel extends _$AccessKeyViewModel {
  AccessKeyRepository get _remoteRepository =>
      ref.read(accessKeyRepositoryProvider);
  FirestoreRepository get _firestoreRepository =>
      ref.read(firestoreRepositoryProvider);

  Future<bool> updateAccessKeyDataLimit({
    required OutlineServer server,
    required String accessKeyId,
    DataLimit? dataLimit,
  }) async {
    if (server.outlineManagementApiUrl == null) {
      throw Exception('Server management URL is null');
    }
    final result = await _remoteRepository.updateAccessKeyDataLimit(
      accessKeyId: accessKeyId,
      bytes: dataLimit?.bytes,
    );
    if (result) {
      final current = await future;
      final updatedList = current.map((key) {
        if (key.outlineId != accessKeyId) return key;
        return key.copyWith(dataLimit: dataLimit);
      }).toList();
      final updatedKey = updatedList.firstWhere(
        (key) => key.outlineId == accessKeyId,
      );
      await _firestoreRepository.upsertAccessKey(updatedKey);
      state = AsyncData(updatedList);
    }
    return result;
  }

  @override
  FutureOr<List<AccessKey>> build(OutlineServer server) async {
    final remoteKeys = await _remoteRepository.getAllAccessKeys();
    return _mergeRemoteWithLocal(remoteKeys, server);
  }

  Future<void> addAccessKey(
    String name, {
    DateTime? expiredDate,
    String? note,
  }) async {
    final newKey = await _remoteRepository.createAccessKey(
      name: name,
      expiredDate: expiredDate,
    );
    final server = this.server;
    final normalizedNote = _normalizeNote(note);
    await _firestoreRepository.upsertAccessKey(
      newKey.copyWith(
        serverId: server.serverId,
        expiredDate: expiredDate,
        noteProvided: true,
        note: normalizedNote,
      ),
    );
    await _reloadFromRemote(server);
  }

  Future<void> updateAccessKey(
    String outlineId, {
    String? name,
    DateTime? expiredDate,
    String? note,
    bool noteProvided = false,
  }) async {
    // Update on server if name is provided
    if (name != null) {
      await _remoteRepository.updateAccessKeyName(id: outlineId, name: name);
    }
    // Update Firestore cache with local-only data
    final current = await future;
    final normalizedNote = noteProvided ? _normalizeNote(note) : null;
    final updatedList = current.map((key) {
      if (key.outlineId != outlineId) return key;
      return key.copyWith(
        name: name ?? key.name,
        expiredDate: expiredDate ?? key.expiredDate,
        noteProvided: noteProvided,
        note: normalizedNote,
      );
    }).toList();
    final updatedKey = updatedList.firstWhere(
      (key) => key.outlineId == outlineId,
    );
    await _firestoreRepository.upsertAccessKey(updatedKey);
    ref.invalidate(serverDashboardProvider);
    state = AsyncData(updatedList);
  }

  Future<void> deleteAccessKey(String outlineId) async {
    await _remoteRepository.deleteAccessKey(id: outlineId);
    final current = await future;
    AccessKey? target;
    for (final key in current) {
      if (key.outlineId == outlineId) {
        target = key;
        break;
      }
    }
    if (target != null) {
      await _firestoreRepository.deleteAccessKey(target.id);
    }
    await _reloadFromRemote(server);
  }

  Future<void> refresh() async {
    await _reloadFromRemote(server);
  }

  Future<void> _reloadFromRemote(OutlineServer server) async {
    final remoteKeys = await _remoteRepository.getAllAccessKeys();
    state = AsyncData(await _mergeRemoteWithLocal(remoteKeys, server));
    ref.invalidate(serverDashboardProvider);
  }

  Future<List<AccessKey>> _mergeRemoteWithLocal(
    List<AccessKey> remoteKeys,
    OutlineServer server,
  ) async {
    final normalized = remoteKeys
        .map((key) => key.copyWith(serverId: server.serverId))
        .toList();
    final localKeys = await _firestoreRepository.getAccessKeys(
      serverId: server.serverId,
    );
    final localKeyMap = {for (var key in localKeys) key.id: key};

    log(
      "localKeyMap keys: ${localKeyMap.keys.toList()} localKeys: ${localKeys.isNotEmpty ? localKeys.map((k) => k.id).join(', ') : 'none'}",
    );

    // Build set of remote key IDs to detect orphaned local keys
    final remoteKeyIds = {for (var key in normalized) key.id};

    // Upsert all remote keys with preserved local metadata
    for (final key in normalized) {
      final local = localKeyMap[key.id];
      await _firestoreRepository.upsertAccessKey(
        key.copyWith(
          expiredDate: local?.expiredDate,
          noteProvided: local != null,
          note: local?.note,
        ),
      );
    }

    // Delete orphaned keys (exist in Firestore but not on remote server)
    for (final localKey in localKeys) {
      if (!remoteKeyIds.contains(localKey.id)) {
        log('Deleting orphaned key from Firestore: ${localKey.id}');
        await _firestoreRepository.deleteAccessKey(localKey.id);
      }
    }

    return normalized.map((key) {
      final local = localKeyMap[key.id];
      if (local != null) {
        var updated = key;
        if (local.expiredDate != null) {
          updated = updated.copyWith(expiredDate: local.expiredDate);
        }
        updated = updated.copyWith(noteProvided: true, note: local.note);
        return updated;
      }
      return key;
    }).toList();
  }

  String? _normalizeNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
