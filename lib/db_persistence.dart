import 'package:clusterup/ssh_key.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:core';
import 'dart:io';
import 'cluster.dart';
import 'cluster_child.dart';

// https://flutter.dev/docs/cookbook/persistence/sqlite
class DBPersistence {
  //! deletes DB file
  static Future<void> deleteDB() async {
    String filename = [await getDatabasesPath(), 'cluster_up.db'].join('/');
    File file = File(filename);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  final Future<Database> database = openDatabase(
    [getDatabasesPath(), 'cluster_up.db'].join('/'),
    onCreate: (db, version) {
      db.execute(
        "CREATE TABLE clusters(id INTEGER PRIMARY KEY, name TEXT, user TEXT, host TEXT, port INTEGER, enabled INTEGER, actions TEXT)",
      );
      db.execute(
        "CREATE TABLE ssh_keys(id TEXT PRIMARY KEY, private TEXT)",
      );
      db.execute(
        "CREATE TABLE children(parent INTEGER, id INTEGER, user TEXT, host TEXT, port INTEGER, enabled INTEGER, PRIMARY KEY(parent,id))",
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

    // remove old
    db.delete(
      "children",
      where: "parent=?",
      whereArgs: [cluster.id],
    );

    // add new
    cluster.children.forEach((ClusterChild child) async {
      await _addChild(child);
    });
  }

  Future<void> _addChild(ClusterChild child) async {
    final Database db = await database;
    await db.insert(
      'children',
      child.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setClusters(List<Cluster> clusters) async {
    final Database db = await database;
    await db.delete('clusters');
    clusters.forEach((cluster) async {
      await db.insert(
        'clusters',
        cluster.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> setSSHKey(SSHKey key) async {
    if (key == null) return;

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
    final List<Map<String, dynamic>> clusters = await db.query('clusters');
    final List<Map<String, dynamic>> children = await db.query('children');

    return List.generate(clusters.length, (i) {
      Cluster cluster = Cluster.fromMap(clusters[i]);
      final List<Map<String, dynamic>> ours = children.where((element) => element["parent"] == cluster.id).toList();
      ours.forEach((Map<String, dynamic> one) {
        cluster.children.add(ClusterChild.fromMap(cluster, one));
      });
      return cluster;
    });
  }
}
