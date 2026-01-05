# Outline Manager – Copilot Instructions

## Project Snapshot
- Flutter + Riverpod app for administering Outline VPN servers; `main.dart` initializes Firebase then routes through `AuthGate` (`lib/src/views/auth/`) before landing on `ServersScreen`.
- Authentication uses Firebase email/password (login only). See `LoginScreen` for the UI flow and `firebase_providers.dart` for shared instances.
- Data persists in Firestore under `users/{uid}/servers` and `users/{uid}/access_keys`, managed by `FirestoreRepository`.
- Core flow: user signs in → sees cached server list → selects a server to set the base URL → manages access keys/metrics via `AccessKeysScreen` and `AccessKeyDetail`.

## Architecture & Data Flow
- `BaseUrlProvider` stores the active Outline management URL. Always call `baseUrlProviderProvider.notifier.setupUrl(url)` before hitting any Outline endpoint (the server tile tap already does this).
- `ServerViewModel` now uses `FirestoreRepository` to save servers per Firebase user. `addServer` fetches `/server`, stamps `outlineManagementApiUrl`, then `upsertServer` writes the doc under `users/{uid}/servers/{serverId}`.
- `AccessKeyViewModel.build(server)` fetches all remote keys via Outline, normalizes them to the selected `serverId`, merges Firestore overrides (currently `expiredDate`), and rehydrates Firestore so offline mode stays warm.
- `FirestoreRepository` encapsulates Firestore CRUD and enforces `users/{uid}` scoping via the signed-in FirebaseAuth user. Do not access Firestore directly from views.
- Outline REST repositories (`server_repository.dart`, `access_key_repository.dart`) remain stateless Dio wrappers; orchestration lives in view models.

## State, Persistence, and Metrics
- `expiredDate` remains a local-only field; Firestore stores the override while remote Outline data continues to win for everything else.
- `AccessKeyRepository.getAllAccessKeys` must keep handling both `List` and `{accessKeys: [...]}` payloads plus `/metrics/transfer` enrichment; `AccessKeyViewModel` then calls `_mergeRemoteWithLocal` to write those values to Firestore and overlay local metadata.
- Firestore collections: `users/{uid}/servers` mirrors `OutlineServer.toJson()`, and `users/{uid}/access_keys` stores `AccessKey` documents keyed by Outline `id` (including `serverId` for filtering).
- When updating keys (name or expiration), call the Outline API first (when applicable) and then `FirestoreRepository.upsertAccessKey`/`deleteAccessKey` so the cache stays consistent for subsequent rebuilds and offline use.

## Networking Practices
- Outline endpoints in use: `GET /server`, `GET/POST/PUT/DELETE /access-keys`, `GET /metrics/transfer`, `PUT /server/access-key-data-limit`.
- `AccessKeyDetail`'s “Data limit” action calls `accessKeyViewModelProvider(server).notifier.updateAccessKeyDataLimit`; never call it unless `OutlineServer.outlineManagementApiUrl` is non-null.
- For operations requiring a raw management URL (e.g., data-limit updates), pass `OutlineServer.outlineManagementApiUrl` directly instead of the base URL stored in the repository instance.
- Dio adapters disable certificate validation; do not remove that unless you also update backend TLS handling.

## UI Workflow Cues
- `AuthGate` listens to `authStateProvider` and toggles between `LoginScreen` (email/password sign-in only) and `ServersScreen`.
- `ServersScreen` now includes a logout action (`firebaseAuthProvider.signOut`). All server mutations still flow through `serverViewModelProvider` so Firestore caches refresh.
- `AccessKeysScreen` → `AddAccessKeyPage` still returns `{name, expiredDate}`; the notifier handles Outline + Firestore writes. Use the notifier methods (`addAccessKey`, `updateAccessKey`, `deleteAccessKey`, `updateAccessKeyDataLimit`) instead of touching repositories directly.
- `AccessKeyDetail` remains the hub for copy/delete/edit/data-limit operations; ensure the notifier gets called so parent lists refresh automatically.

## Tooling & Dev Workflow
- Dependencies: `flutter pub get` (ensure Firebase iOS/Android configs are added via `flutterfire configure` or platform-specific plist/json files).
- Riverpod codegen: `flutter pub run build_runner build --delete-conflicting-outputs` after touching any `@riverpod` declarations (`firebase_providers.dart`, `repository_provider.dart`, `view_model/**`).
- Formatting & static checks: `dart format .` then `flutter analyze` (rules in `analysis_options.yaml`).
- Tests: `flutter test` (light coverage today—widget smoke test under `test/`).
- Run with `flutter run` for the desired platform; Firebase requires platform setup (`GoogleService-Info.plist`, `google-services.json`, etc.) before the app can sign in.
