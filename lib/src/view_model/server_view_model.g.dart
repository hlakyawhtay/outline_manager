// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerViewModel)
const serverViewModelProvider = ServerViewModelProvider._();

final class ServerViewModelProvider
    extends $AsyncNotifierProvider<ServerViewModel, List<OutlineServer>> {
  const ServerViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverViewModelHash();

  @$internal
  @override
  ServerViewModel create() => ServerViewModel();
}

String _$serverViewModelHash() => r'539e9b62643d3850798f4423201c98e3b3fee88e';

abstract class _$ServerViewModel extends $AsyncNotifier<List<OutlineServer>> {
  FutureOr<List<OutlineServer>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<OutlineServer>>, List<OutlineServer>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<OutlineServer>>, List<OutlineServer>>,
              AsyncValue<List<OutlineServer>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
