import 'package:sqflite/sqflite.dart';
import 'dart:core';
import 'cluster.dart';

// https://flutter.dev/docs/cookbook/persistence/sqlite
class Persistence {
  final Future<Database> database = openDatabase(
    [getDatabasesPath(), 'cluster_up.db'].join(),
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE clusters(id INTEGER PRIMARY KEY, name TEXT, user TEXT, host TEXT, port INTEGER)",
      );
    },
    version: 1,
  );

  Future<void> addCluster(Cluster cluster) async {
    final Database db = await database;
    await db.insert(
      'clusters',
      cluster.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeCluster(Cluster cluster) async {
    final Database db = await database;
    await db.delete(
      'clusters',
      where: "id = ?",
      whereArgs: [cluster.id],
    );
  }

  Future<List<Cluster>> readClusters() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clusters');
    return List.generate(maps.length, (i) {
      return Cluster(
        maps[i]['id'],
        maps[i]['name'],
        maps[i]['user'],
        maps[i]['host'],
        maps[i]['port'],
      );
    });
  }
}
