import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:clusterup/log.dart';
import 'load_save_view.dart';
import 'cluster_results_view.dart';
import 'log_view.dart';
import 'remote_actions_view.dart';
import 'cluster_view.dart';
import 'key_view.dart';
import '../db_persistence.dart';
import '../cluster.dart';
import '../ssh_key.dart';
import '../clusterup_data.dart';

class ClustersViewState extends State<ClustersView> {
  Future<DBPersistence> _db = DBPersistence.create();
  ClusterUpData _data = ClusterUpData();

  @override
  void initState() {
    _db.then((db) {
      db.getSSHKey().then((sshKey) {
        log("Loaded ssh key");
        _data.sshKey = sshKey;
      });

      db.readClusters().then((clusters) {
        log("Loaded ${clusters.length} clusters");
        _data.clusters = clusters;
        setState(() {});
      });
    });
    super.initState();
  }

  Widget _buildClustersOverview() {
    return ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        onReorder: (int oldIndex, int newIndex) {
          // https://api.flutter.dev/flutter/material/ReorderableListView-class.html
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            log("Moved $oldIndex to $newIndex");
            Cluster item = _data.clusters.removeAt(oldIndex);
            _data.clusters.insert(newIndex, item);
            for (int i = 0; i < _data.clusters.length; ++i) {
              _data.clusters[i].id = i;
              _data.clusters[i].persist();
            }
          });
        },
        itemCount: _data.clusters.length,
        itemBuilder: (context, i) {
          return _buildRow(_data.clusters[i]);
        });
  }

  Widget _buildRow(Cluster cluster) {
    Widget trailing = cluster.running
        ? Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              child: CircularProgressIndicator(),
              height: 15.0,
              width: 15.0,
            ),
          )
        : IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: cluster.statusColor(),
              size: 30,
            ),
            onPressed: () {
              if (cluster.running) return;
              if (_data.sshKey == null) {
                log("ssh key is null");
                return;
              }
              log("Play : $cluster");
              cluster.run(_data.sshKey!).then((v) {
                setState(() {});
              });
              setState(() {});
            },
          );

    return ListTile(
      contentPadding: EdgeInsets.only(left: 8),
      horizontalTitleGap: 0,
      key: Key("cluster ${cluster.id}"),
      leading: Padding(
        padding: const EdgeInsets.only(top: 3, right: 6),
        child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _showLastRun(cluster);
            },
            iconSize: 20,
            icon: FaIcon(
              FontAwesomeIcons.networkWired,
              size: 20,
              color: cluster.statusColor(),
            )),
      ),
      title: SingleChildScrollView(
        child: Text(cluster.name),
        scrollDirection: Axis.horizontal,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          trailing,
          _buildClusterMenuButton(cluster),
        ],
      ),
      onTap: () {
        _showCluster(cluster);
      },
    );
  }

  void _showCluster(Cluster cluster) async {
    log("_showCluster : $cluster");
    var db = await _db;
    cluster.persist = () => db.addCluster(cluster);
    final Cluster? result =
        await Navigator.of(context).push(MaterialPageRoute<Cluster>(builder: (BuildContext context) {
      return ClusterView(_data.sshKey, cluster);
    }));
    if (result != null) {
      log("_showCluster : Updating $cluster");
      db.addCluster(result);
      setState(() {});
    }
  }

  // https://stackoverflow.com/a/53861303
  void _clustersMenu() async {
    final Cluster? result = await Navigator.of(context).push(
      MaterialPageRoute<Cluster>(
        builder: (BuildContext context) {
          return ClusterView.newCluster(_data.sshKey, _data.clusters.length);
        },
      ),
    );

    if (result != null) {
      log("Adding $result");
      _data.clusters.add(result);
      var db = await _db;
      db.addCluster(result);
    }

    setState(() {});
  }

  void _keyMenu() async {
    _data.sshKey = await Navigator.of(context).push(
      MaterialPageRoute<SSHKey>(
        builder: (BuildContext context) {
          return KeyView(_data.sshKey);
        },
      ),
    );

    if (_data.sshKey != null) {
      var db = await _db;
      db.setSSHKey(_data.sshKey);
    }
  }

  void _actionsMenu() async {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ActionsView();
        },
      ),
    );
  }

  void _loadSaveMenu() async {
    ClusterUpData? data = await Navigator.of(context).push(
      MaterialPageRoute<ClusterUpData>(
        builder: (BuildContext context) {
          return LoadSaveView(_data);
        },
      ),
    );

    if (data != null) {
      _data = data;
      var db = await _db;
      db.setClusters(_data.clusters);
      db.setSSHKey(_data.sshKey);
      setState(() {});
    }
  }

  void _viewLog() async {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return LogView();
        },
      ),
    );
    setState(() {});
  }

  void _aboutMenu() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Cluster Up v${packageInfo.version}"),
            content: Text("Monitor health of your servers"),
          );
        });
  }

  PopupMenuButton<ClusterOpts> _buildClusterMenuButton(Cluster cluster) {
    return PopupMenuButton<ClusterOpts>(
      key: Key("clusterOptionsMenu"),
      onSelected: (ClusterOpts result) async {
        switch (result) {
          case ClusterOpts.Remove:
            {
              log("Remove");
              log("Removing $cluster");
              _data.clusters.remove(cluster);
              var db = await _db;
              db.removeCluster(cluster);
              setState(() {});
            }
            break;
          case ClusterOpts.LastRun:
            {
              log("Show last run");
              _showLastRun(cluster);
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ClusterOpts>>[
        const PopupMenuItem<ClusterOpts>(
          value: ClusterOpts.Remove,
          child: Text("Remove"),
        ),
        const PopupMenuItem<ClusterOpts>(
          value: ClusterOpts.LastRun,
          child: Text("Last Run"),
        ),
      ],
    );
  }

  void _showLastRun(Cluster cluster) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return ClusterResultsView(cluster);
    }));
    setState(() {});
  }

  PopupMenuButton<ClustersOpts> _buildClustersPopUpButton() {
    String keyText = (_data.sshKey != null) ? "View SSH Key" : "Generate SSH Key";
    return PopupMenuButton<ClustersOpts>(
      key: Key("optionsMenu"),
      onSelected: (ClustersOpts result) {
        switch (result) {
          case ClustersOpts.Key:
            {
              log("Key");
              _keyMenu();
            }
            break;
          case ClustersOpts.Actions:
            {
              log("Key");
              _actionsMenu();
            }
            break;
          case ClustersOpts.LoadSave:
            {
              log("Load/Save");
              _loadSaveMenu();
            }
            break;
          case ClustersOpts.ViewLog:
            {
              log("View Log");
              _viewLog();
            }
            break;
          case ClustersOpts.About:
            {
              log("About");
              _aboutMenu();
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ClustersOpts>>[
        PopupMenuItem<ClustersOpts>(
          value: ClustersOpts.Key,
          child: Text(keyText),
        ),
        const PopupMenuItem<ClustersOpts>(
          value: ClustersOpts.Actions,
          child: Text("Actions"),
        ),
        const PopupMenuItem<ClustersOpts>(
          value: ClustersOpts.LoadSave,
          child: Text('Load/Save'),
        ),
        const PopupMenuItem<ClustersOpts>(
          value: ClustersOpts.ViewLog,
          child: Text('View Log'),
        ),
        const PopupMenuItem<ClustersOpts>(
          value: ClustersOpts.About,
          child: Text('About'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clusters'),
        actions: <Widget>[
          _buildClustersPopUpButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: Key("addCluster"),
        backgroundColor: Color(0xff616161),
        foregroundColor: Color(0xffc7c7c7),
        onPressed: () {
          _clustersMenu();
        },
        child: const Icon(Icons.add),
      ),
      body: _buildClustersOverview(),
    );
  }
}

enum ClustersOpts { Key, Actions, LoadSave, ViewLog, About }

enum ClusterOpts { Remove, LastRun }

class ClustersView extends StatefulWidget {
  @override
  ClustersViewState createState() => ClustersViewState();
}
