import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/outline_server.dart';
import '../providers/repository_provider.dart';
import '../repository/firestore_repository.dart';
import 'server_dashboard_provider.dart';

part 'server_view_model.g.dart';

@riverpod
class ServerViewModel extends _$ServerViewModel {
  @override
  Future<List<OutlineServer>> build() async {
    final firestoreRepo = ref.read(firestoreRepositoryProvider);
    return await firestoreRepo.getServers();
  }

  Future<void> addServer(String managementUrl) async {
    ref.read(baseUrlProviderProvider.notifier).setupUrl(managementUrl);
    final firestoreRepo = ref.read(firestoreRepositoryProvider);
    final repo = ref.read(serverRepositoryProvider);
    try {
      final OutlineServer server = await repo.getServerInfo();
      server.outlineManagementApiUrl = managementUrl;
      await firestoreRepo.upsertServer(server);

      state = AsyncValue.data(await firestoreRepo.getServers());
      ref.invalidate(serverDashboardProvider);
    } catch (e, st) {
      log("Error : ${e.toString()}");
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeServer(String serverId) async {
    final firestoreRepo = ref.read(firestoreRepositoryProvider);
    try {
      await firestoreRepo.deleteServer(serverId);
      ref.invalidate(serverDashboardProvider);
      state = AsyncValue.data(await firestoreRepo.getServers());
    } catch (e, st) {
      log("Error : \\${e.toString()}");
      state = AsyncValue.error(e, st);
    }
  }
}
