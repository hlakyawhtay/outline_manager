import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/access_keys.dart';
import '../model/outline_server.dart';
import '../providers/firebase_providers.dart';

part 'firestore_repository.g.dart';

class FirestoreRepository {
  FirestoreRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to access Firestore data');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _serversCollection =>
      _firestore.collection('users').doc(_uid).collection('servers');

  CollectionReference<Map<String, dynamic>> get _accessKeysCollection =>
      _firestore.collection('users').doc(_uid).collection('access_keys');

  Future<List<OutlineServer>> getServers() async {
    final snapshot = await _serversCollection.get();
    return snapshot.docs
        .map((doc) => OutlineServer.fromJson(doc.data()))
        .toList();
  }

  Future<void> upsertServer(OutlineServer server) async {
    await _serversCollection
        .doc(server.serverId)
        .set(_serverToFirestoreMap(server), SetOptions(merge: true));
  }

  Future<void> deleteServer(String serverId) async {
    await _serversCollection.doc(serverId).delete();
    final keys = await _accessKeysCollection
        .where('serverId', isEqualTo: serverId)
        .get();
    for (final doc in keys.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<AccessKey>> getAccessKeys({String? serverId}) async {
    Query<Map<String, dynamic>> query = _accessKeysCollection;
    if (serverId != null) {
      query = query.where('serverId', isEqualTo: serverId);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => _accessKeyFromFirestore(doc.data()))
        .toList();
  }

  Future<void> upsertAccessKey(AccessKey key) async {
    await _accessKeysCollection
        .doc(key.id)
        .set(_accessKeyToFirestoreMap(key), SetOptions(merge: true));
  }

  Future<List<AccessKey>> searchAccessKeysByName(
    String query, {
    int limit = 20,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return [];
    }
    final snapshot = await _accessKeysCollection.get();
    final results = <AccessKey>[];
    for (final doc in snapshot.docs) {
      final key = _accessKeyFromFirestore(doc.data());
      final comparisonSource = (key.name.isNotEmpty ? key.name : key.outlineId)
          .toLowerCase();
      final noteSource = key.note?.toLowerCase() ?? '';
      if (comparisonSource.contains(normalized) ||
          noteSource.contains(normalized)) {
        results.add(key);
      }
      if (results.length >= limit) {
        break;
      }
    }
    return results;
  }

  Future<void> updateAccessKeyExpiredDate(
    String id,
    DateTime? expiredDate,
  ) async {
    await _accessKeysCollection.doc(id).update({
      'expiredDate': expiredDate != null
          ? Timestamp.fromDate(expiredDate)
          : null,
    });
  }

  Future<void> deleteAccessKey(String id) async {
    await _accessKeysCollection.doc(id).delete();
  }

  Map<String, dynamic> _serverToFirestoreMap(OutlineServer server) {
    return {
      'name': server.name,
      'serverId': server.serverId,
      'metricsEnabled': server.metricsEnabled,
      'createdTimestampMs': server.createdTimestampMs,
      'version': server.version,
      'portForNewAccessKeys': server.portForNewAccessKeys,
      'hostnameForAccessKeys': server.hostnameForAccessKeys,
      'outlineManagementApiUrl': server.outlineManagementApiUrl,
    };
  }

  Map<String, dynamic> _accessKeyToFirestoreMap(AccessKey key) {
    return {
      'id': key.id,
      'outlineId': key.outlineId,
      'name': key.name,
      'password': key.password,
      'port': key.port,
      'method': key.method,
      'dataLimit': key.dataLimit?.toJson(),
      'accessUrl': key.accessUrl,
      'expiredDate': key.expiredDate != null
          ? Timestamp.fromDate(key.expiredDate!)
          : null,
      'serverId': key.serverId,
      'bytesTransferred': key.bytesTransferred,
      'note': key.note,
    };
  }

  AccessKey _accessKeyFromFirestore(Map<String, dynamic> data) {
    DateTime? expiredDate;
    final rawExpiry = data['expiredDate'];
    if (rawExpiry is Timestamp) {
      expiredDate = rawExpiry.toDate();
    } else if (rawExpiry is DateTime) {
      expiredDate = rawExpiry;
    }

    final storedId = data['id'] as String? ?? '';
    final serverId = data['serverId'] as String?;
    final outlineId =
        data['outlineId'] as String? ??
        _deriveOutlineIdFallback(storedId, serverId);

    return AccessKey(
      id: storedId,
      outlineId: outlineId,
      name: data['name'] as String? ?? '',
      password: data['password'] as String? ?? '',
      port: (data['port'] as num?)?.toInt() ?? 0,
      method: data['method'] as String? ?? '',
      dataLimit: data['dataLimit'] != null
          ? DataLimit.fromJson(
              Map<String, dynamic>.from(data['dataLimit'] as Map),
            )
          : null,
      accessUrl: data['accessUrl'] as String? ?? '',
      expiredDate: expiredDate,
      bytesTransferred: (data['bytesTransferred'] as num?)?.toInt(),
      serverId: serverId,
      note: data['note'] as String?,
    );
  }

  String _deriveOutlineIdFallback(String storedId, String? serverId) {
    if (storedId.isEmpty) {
      throw StateError('Stored access key is missing an id');
    }
    if (serverId != null && serverId.isNotEmpty) {
      final prefix = '${serverId}_';
      if (storedId.startsWith(prefix) && storedId.length > prefix.length) {
        return storedId.substring(prefix.length);
      }
    }
    return storedId;
  }
}

@Riverpod(keepAlive: true)
FirestoreRepository firestoreRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return FirestoreRepository(firestore: firestore, auth: auth);
}
