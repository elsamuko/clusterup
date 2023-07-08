import 'package:clusterup/cluster.dart';
import 'package:clusterup/cluster_child.dart';
import 'package:clusterup/db_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  databaseFactory = databaseFactoryFfi;

  test('DBPersistence', () async {
    await DBPersistence.deleteDB();
    String bad = [getDatabasesPath(), 'cluster_up.db'].join('/');
    String fromResources = Directory.current.path + "/res/v1.db";
    expect(File(fromResources).existsSync(), true);

    // write bad named database
    Directory("${getDatabasesPath()}").createSync();
    File(fromResources).copySync(bad);

    // db had the wrong filename and was renamed
    var db = await DBPersistence.create();
    expect(db.renamed, true);

    // content is from db from resources
    List<Cluster> read = await db.readClusters();
    expect(read.last.id, 1);
    expect(read.last.children.last.user, "user2");
    expect(read.last.children.length, 1);
  });
}
