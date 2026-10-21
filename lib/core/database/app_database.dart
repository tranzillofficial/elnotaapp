import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:get/get.dart';
import '../../core/utils/app_constants.dart';
import 'database_impl.dart';

part 'app_database.g.dart';

/// Bare Drift database used as a raw SQL engine.
/// drift_dev/build_runner is absent; the @DriftDatabase annotation is removed
/// so the stub g.dart compiles cleanly. All schema management and queries are
/// in [AppDao] (database_impl.dart) via customSelect / customInsert.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  int get schemaVersion => AppConstants.dbVersion;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: AppConstants.dbFileName);
  }

  /// Factory that also runs PRAGMA setup.
  static Future<AppDatabase> open() async {
    final db = AppDatabase(_openConnection());
    // WAL mode + foreign keys
    await db.customStatement('PRAGMA journal_mode=WAL');
    await db.customStatement('PRAGMA foreign_keys=ON');
    // Create tables via DAO
    await AppDao(db).createTables();
    return db;
  }
}

/// GetX service — singleton database + DAO access.
class DatabaseService extends GetxService {
  static DatabaseService get to => Get.find<DatabaseService>();

  late final AppDatabase db;
  late final AppDao dao;

  /// Called from initServices after await.
  void attach(AppDatabase database) {
    db = database;
    dao = AppDao(database);
  }

  @override
  void onClose() {
    db.close();
    super.onClose();
  }
}
