// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_key_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccessKeyViewModel)
const accessKeyViewModelProvider = AccessKeyViewModelFamily._();

final class AccessKeyViewModelProvider
    extends $AsyncNotifierProvider<AccessKeyViewModel, List<AccessKey>> {
  const AccessKeyViewModelProvider._({
    required AccessKeyViewModelFamily super.from,
    required OutlineServer super.argument,
  }) : super(
         retry: null,
         name: r'accessKeyViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accessKeyViewModelHash();

  @override
  String toString() {
    return r'accessKeyViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AccessKeyViewModel create() => AccessKeyViewModel();

  @override
  bool operator ==(Object other) {
    return other is AccessKeyViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accessKeyViewModelHash() =>
    r'066d31287ccc2c25ff1b0345879ca6dbd63d2d26';

final class AccessKeyViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          AccessKeyViewModel,
          AsyncValue<List<AccessKey>>,
          List<AccessKey>,
          FutureOr<List<AccessKey>>,
          OutlineServer
        > {
  const AccessKeyViewModelFamily._()
    : super(
        retry: null,
        name: r'accessKeyViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AccessKeyViewModelProvider call(OutlineServer server) =>
      AccessKeyViewModelProvider._(argument: server, from: this);

  @override
  String toString() => r'accessKeyViewModelProvider';
}

abstract class _$AccessKeyViewModel extends $AsyncNotifier<List<AccessKey>> {
  late final _$args = ref.$arg as OutlineServer;
  OutlineServer get server => _$args;

  FutureOr<List<AccessKey>> build(OutlineServer server);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<List<AccessKey>>, List<AccessKey>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AccessKey>>, List<AccessKey>>,
              AsyncValue<List<AccessKey>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
