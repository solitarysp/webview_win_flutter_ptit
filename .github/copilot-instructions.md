# Copilot Instructions for this Repository

## Build, test, lint

- Install dependencies: `make deps` (wraps `flutter pub get`)
- Run app:
  - `make start PLATFORM=macos|ios|aos|windows`
  - handy shortcuts: `make start-macos`, `make start-ios`, `make start-ios-sim`, `make start-aos`, `make start-windows`
  - or direct: `flutter run -d <device>`
- Build app:
  - `make build PLATFORM=macos|ios|aos|windows`
  - Android release artifacts: `make build-aos` (APK + AAB)
- Lint/static analysis: `flutter analyze`
- Tests:
  - Full suite: `flutter test`
  - Single file: `flutter test test/widget_test.dart`
  - Single test case: `flutter test test/widget_test.dart --plain-name "renders dashboard by default"`
  - Feature-focused example: `flutter test test/features/database_connection/views/database_connection_session_page_test.dart`

## High-level architecture

- App shell is in `lib/main.dart` and `lib/app/dev_workbench_app.dart`.
  - `MaterialApp` sets theme, responsive breakpoints, localization delegates, and persisted locale resolution.
  - Main routes:
    - `/dashboard` -> `DevWorkbenchPage`
    - `/settings` -> `WorkbenchSettingsPage`
    - `/faq` -> `WorkbenchFaqPage`
    - `/database` -> `DatabaseConnectionPage`
    - `/remote-ops-ssh` -> `RemoteOpsSshPage`
  - Dashboard is the default entry point.
- Workbench domain (`lib/features/workbench/**`):
  - Static domain catalog in `data/feature_catalog.dart` + locale-aware projection via `localizedFeatureCatalog(...)`.
  - Filter/search/selection state in `state/workbench_controller.dart`.
  - Dashboard CTA opens real flows for `Data Platform` (`/database`) and `Remote Ops & SSH` (`/remote-ops-ssh`); FAQ is a dedicated route.
- Database connection domain (`lib/features/database_connection/**`) is layered:
  - `models/`: profile/session/sync/result/history/settings models
  - `data/database_connection_store.dart`: local persistence via `SharedPreferences`
  - `services/`: connectivity test, MySQL session lifecycle, SQL execution, sync push
  - `state/database_connection_controller.dart`: orchestration + UI-facing state
  - `views/` + `views/widgets/`: list/create/session/history/analysis/query screens
- Remote Ops SSH domain (`lib/features/remote_ops_ssh/**`) mirrors the same layering pattern:
  - local profile + shared credential persistence in `data/remote_ops_ssh_store.dart`
  - runtime orchestration in `state/remote_ops_ssh_controller.dart`
  - SSH/SFTP/forwarding execution in `services/remote_ops_ssh_service.dart`
  - UI in `views/remote_ops_ssh_page*.dart`
- Runtime data flow (database and SSH features):
  1. UI events call domain controller (`DatabaseConnectionController` or `RemoteOpsSshController`)
  2. Controller mutates runtime state and notifies widgets
  3. Controller delegates side effects to services (`mysql1`, `dartssh2`, `http`, sockets)
  4. Persistent state (profiles/settings/pending sync/history metadata) is stored locally

## Key repository conventions

- State management pattern:
  - `ChangeNotifier` controllers own mutable UI/runtime state.
  - Stateful pages attach/detach listeners in `initState`/`dispose`; rendering refresh is driven by controller notifications.
- Localization convention:
  - All user-facing text must be internationalized (no hardcoded UI copy in widgets/pages).
  - UI strings must come from `context.l10n` and be defined in ARB files (`lib/l10n/*.arb`).
  - When adding new text, update the ARB resources and generated localization accessors in the same change.
  - Locale is persisted by `AppLocaleController`; settings changes must reflect immediately in UI.
- Database session model is runtime-first:
  - `sessionId` is distinct from `profileId`.
  - Multiple concurrent sessions per profile are supported in `_sessionRuntimes`.
  - Reconnect behavior is one-shot when disconnect is detected.
- SQL workbench is MySQL-only end-to-end:
  - Non-MySQL engines are currently limited to reachability checks in `DatabaseConnectionTester`.
  - SQL/table explorer flows must use `runSqlInSession` / `loadTablesForSession`.
  - Table quick actions execute immediately without overwriting editor text.
  - Schema mutations (`create/drop/alter/rename/truncate table`) trigger table reload.
  - Query result rendering is capped (`maxRows = 100` in `MySqlWorkbenchService`).
- Remote Ops SSH conventions:
  - Profile auth mode must stay consistent with selected shared credential type (`password` vs `privateKey`).
  - Terminal session is persistent across commands until explicit disconnect.
- Connectivity conventions for local/dev:
  - Normalize `localhost` to `127.0.0.1`.
  - DNS resolve + SSL fallback are implemented across DB tester/session/workbench services.
- Persistence and sync conventions:
  - SharedPreferences keys for DB flow:
    - `db_connection_profiles`
    - `db_connection_sync_config`
    - `db_connection_pending_sync`
  - Profile changes enqueue `PendingSyncOperation` (`upsert`/`delete`) and may auto-push via sync service.
- Logging and sensitive data:
  - Use `DbDebugLogger` for DB diagnostics (active only in `kDebugMode`).
  - Credentials must stay masked in debug output.
- Documentation sync convention:
  - Keep `docs/FEATURES.md` and taxonomy docs in `docs/02-current-features/*`, `docs/03-code-logic/*` aligned with behavior changes.
- UI copy convention:
  - Product copy is primarily Vietnamese; keep new user-facing text consistent unless a feature intentionally introduces multilingual content.
