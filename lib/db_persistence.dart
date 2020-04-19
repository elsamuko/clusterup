import 'package:clusterup/ssh_key.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:core';
import 'cluster.dart';

// https://flutter.dev/docs/cookbook/persistence/sqlite
class DBPersistence {
  final Future<Database> database = openDatabase(
    [getDatabasesPath(), 'cluster_up.db'].join('/'),
    onCreate: (db, version) {
      db.execute(
        "CREATE TABLE clusters(id INTEGER PRIMARY KEY, name TEXT, user TEXT, host TEXT, port INTEGER, actions TEXT)",
      );
      db.execute(
        "CREATE TABLE ssh_keys(id TEXT PRIMARY KEY, private TEXT)",
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

  Future<void> setSSHKey(SSHKey key) async {
    final Database db = await database;
    await db.insert(
      'ssh_keys',
      key.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SSHKey> getSSHKey() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ssh_keys');
    var keys = List.generate(maps.length, (i) {
      return SSHKey.fromPEM(
        maps[i]['private'] ?? "",
      );
    });

    if (keys.length > 0)
      return keys.first;
    else
      return null;
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
      return Cluster.fromMap(maps[i]);
    });
  }
}
