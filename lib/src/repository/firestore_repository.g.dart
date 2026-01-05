// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firestoreRepository)
const firestoreRepositoryProvider = FirestoreRepositoryProvider._();

final class FirestoreRepositoryProvider
    extends
        $FunctionalProvider<
          FirestoreRepository,
          FirestoreRepository,
          FirestoreRepository
        >
    with $Provider<FirestoreRepository> {
  const FirestoreRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreRepositoryHash();

  @$internal
  @override
  $ProviderElement<FirestoreRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirestoreRepository create(Ref ref) {
    return firestoreRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirestoreRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirestoreRepository>(value),
    );
  }
}

String _$firestoreRepositoryHash() =>
    r'5d76c71f442c7c39f7ef4939a0479aae6019ff53';
