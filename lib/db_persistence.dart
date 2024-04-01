import 'package:clusterup/ssh_key.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:core';
import 'dart:io';
import 'package:path/path.dart';
import 'cluster.dart';
import 'cluster_child.dart';
import 'log.dart';

void onCreateV1(Database db, int version) async {
  await db.execute(
    "CREATE TABLE clusters(id INTEGER PRIMARY KEY, name TEXT, user TEXT, host TEXT, port INTEGER, enabled INTEGER, actions TEXT)",
  );
  await db.execute(
    "CREATE TABLE ssh_keys(id TEXT PRIMARY KEY, private TEXT)",
  );
  await db.execute(
    "CREATE TABLE children(parent INTEGER, id INTEGER, user TEXT, host TEXT, port INTEGER, enabled INTEGER, PRIMARY KEY(parent,id))",
  );
}

void onCreateV2(Database db, int version) async {
  await db.execute(
    "CREATE TABLE clusters(id INTEGER PRIMARY KEY, name TEXT, user TEXT, host TEXT, port INTEGER, password TEXT, enabled INTEGER, actions TEXT)",
  );
  await db.execute(
    "CREATE TABLE ssh_keys(id TEXT PRIMARY KEY, private TEXT)",
  );
  await db.execute(
    "CREATE TABLE children(parent INTEGER, id INTEGER, user TEXT, host TEXT, port INTEGER, password TEXT, enabled INTEGER, PRIMARY KEY(parent,id))",
  );
}

void updateToV2(Database db, int oldVersion, int newVersion) async {
  if (oldVersion == 1) {
    await db.execute('ALTER TABLE clusters ADD password TEXT');
    await db.execute('ALTER TABLE children ADD password TEXT');
  }
}

// https://flutter.dev/docs/cookbook/persistence/sqlite
class DBPersistence {
  String databasePath;
  Database database;
  bool renamed = false;

  DBPersistence._(this.databasePath, this.database);

  // adb shell run-as com.devsamuko.clusterup ls -Rl databases/
  // https://github.com/tekartik/sqflite/blob/master/sqflite/doc/opening_db.md
  static Future<DBPersistence> create([int version = 2]) async {
    String path = await getDatabasesPath();
    Directory(path).createSync(recursive: true);
    String dbName = join(path, 'cluster_up.db');
    bool renamed = false;

    // fix for wrong filename in older versions
    File badDbName = File("$path/Instance of 'Future<String>'/cluster_up.db");
    if (badDbName.existsSync()) {
      log("renaming $badDbName to $dbName");
      badDbName.renameSync(dbName);
      renamed = true;
    }

    // open db v1 or v2
    Database db = await () {
      switch (version) {
        case 1:
          return openDatabase(
            dbName,
            onCreate: onCreateV1,
            version: 1,
          );
        default:
          return openDatabase(
            dbName,
            onCreate: onCreateV2,
            onUpgrade: updateToV2,
            version: 2,
          );
      }
    }();

    var dbPersistence = DBPersistence._(path, db);
    dbPersistence.renamed = renamed;
    return dbPersistence;
  }

  //! deletes DB file
  static Future<void> deleteDB() async {
    String filename = [await getDatabasesPath(), 'cluster_up.db'].join('/');
    File file = File(filename);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Future<void> addCluster(Cluster cluster) async {
    await database.insert(
      'clusters',
      cluster.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // remove old
    database.delete(
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
    await database.insert(
      'children',
      child.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setClusters(List<Cluster> clusters) async {
    await database.delete('clusters');
    clusters.forEach((cluster) async {
      await database.insert(
        'clusters',
        cluster.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> setSSHKey(SSHKey? key) async {
    if (key == null) return;

    await database.insert(
      'ssh_keys',
      key.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SSHKey?> getSSHKey() async {
    final List<Map<String, dynamic>> maps = await database.query('ssh_keys');
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
    await database.delete(
      'clusters',
      where: "id = ?",
      whereArgs: [cluster.id],
    );
  }

  Future<List<Cluster>> readClusters() async {
    final List<Map<String, dynamic>> clusters = await database.query('clusters');
    final List<Map<String, dynamic>> children = await database.query('children');

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
