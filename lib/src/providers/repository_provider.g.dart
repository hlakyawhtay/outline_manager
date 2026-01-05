// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BaseUrlProvider)
const baseUrlProviderProvider = BaseUrlProviderProvider._();

final class BaseUrlProviderProvider
    extends $NotifierProvider<BaseUrlProvider, String> {
  const BaseUrlProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baseUrlProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baseUrlProviderHash();

  @$internal
  @override
  BaseUrlProvider create() => BaseUrlProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$baseUrlProviderHash() => r'0707cfce2857daef45e430f06035b9dd55d6f2ff';

abstract class _$BaseUrlProvider extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(serverRepository)
const serverRepositoryProvider = ServerRepositoryProvider._();

final class ServerRepositoryProvider
    extends
        $FunctionalProvider<
          ServerRepository,
          ServerRepository,
          ServerRepository
        >
    with $Provider<ServerRepository> {
  const ServerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverRepositoryHash();

  @$internal
  @override
  $ProviderElement<ServerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServerRepository create(Ref ref) {
    return serverRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerRepository>(value),
    );
  }
}

String _$serverRepositoryHash() => r'6ec4a779bb73d39a3aeb107a7d4dd5113f786674';

@ProviderFor(accessKeyRepository)
const accessKeyRepositoryProvider = AccessKeyRepositoryProvider._();

final class AccessKeyRepositoryProvider
    extends
        $FunctionalProvider<
          AccessKeyRepository,
          AccessKeyRepository,
          AccessKeyRepository
        >
    with $Provider<AccessKeyRepository> {
  const AccessKeyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessKeyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessKeyRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccessKeyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccessKeyRepository create(Ref ref) {
    return accessKeyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccessKeyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccessKeyRepository>(value),
    );
  }
}

String _$accessKeyRepositoryHash() =>
    r'5f1509409ef2683d0ae559576543d6adad73fa21';
