# Dependency audit for web/Flutter alignment

The dependency manifests are frozen. No packages were installed into this repository or added/updated/removed. Resolved versions below are read from the existing lockfile.

| Package | Locked version |
|---|---|
| `flutter` | `0.0.0` |
| `flutter_localizations` | `0.0.0` |
| `cupertino_icons` | `1.0.9` |
| `get` | `4.7.3` |
| `intl` | `0.20.2` |
| `get_storage` | `2.1.1` |
| `supabase_flutter` | `2.18.3` |
| `drift` | `2.35.2` |
| `drift_flutter` | `0.3.1` |
| `connectivity_plus` | `7.3.2` |
| `flutter_secure_storage` | `11.2.0` |
| `uuid` | `4.6.0` |
| `path_provider` | `2.1.6` |
| `pdf` | `3.12.0` |
| `printing` | `5.14.3` |
| `file_picker` | `13.1.0` |
| `share_plus` | `13.3.1` |
| `excel` | `4.0.6` |
| `flutter_local_notifications` | `22.3.2` |
| `local_auth` | `3.0.2` |
| `device_info_plus` | `13.3.0` |
| `package_info_plus` | `10.2.2` |
| `workmanager` | `0.10.10` |
| `internet_connection_checker_plus` | `3.1.2` |
| `flutter_test` | `0.0.0` |
| `flutter_lints` | `6.0.0` |
| `flutter_launcher_icons` | `0.14.4` |

Platform assessment: shared GetX/domain/SQL contract code targets all Flutter platforms. This task adds no native plugin. Native SQLite migration tests require a working Flutter toolchain. Web still needs matching Drift WASM/worker assets and DriftWebOptions; file export currently imports dart:io; secure storage, printing, sharing and background plugins require platform-specific validation. Android/iOS/Windows/web parity is not verified by adding schema fields.

SDK requirement from pubspec.yaml: `^3.12.2`. A matching toolchain and all pinned dependencies must be available for the CI job. No unsupported SDK downgrade or dependency re-resolution is included.
