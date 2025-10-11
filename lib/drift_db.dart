import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'drift_db.g.dart';

class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get time => text()();
  IntColumn get value => integer()();
  TextColumn get option => text()();
  TextColumn get symptoms => text().nullable()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Entries, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Initialize sqlite3_flutter_libs for iOS Unicode support
    if (Platform.isIOS) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'peakflow.db'));
    
    return NativeDatabase(
      file,
      logStatements: true,
      setup: (database) {
        // Enable UTF-8 encoding for Unicode support
        database.execute('PRAGMA encoding = "UTF-8"');
        database.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}