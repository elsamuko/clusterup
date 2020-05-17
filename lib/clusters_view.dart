import 'package:clusterup/load_save_view.dart';
import 'package:clusterup/remote_action_results_view.dart';
import 'package:clusterup/remote_actions_view.dart';
import 'package:clusterup/db_persistence.dart';
import 'package:flutter/material.dart';
import 'remote_actions_view.dart';
import 'dart:developer' as dev;
import 'cluster.dart';
import 'cluster_view.dart';
import 'key_view.dart';
import 'ssh_key.dart';
import 'clusterup_data.dart';

class ClustersViewState extends State<ClustersView> {
  DBPersistence _db = DBPersistence();
  ClusterUpData _data = ClusterUpData();

  @override
  void initState() {
    _db.getSSHKey().then((sshKey) {
      _data.sshKey = sshKey;
      setState(() {});
    });

    _db.readClusters().then((clusters) {
      _data.clusters = clusters;
      setState(() {});
    });
    super.initState();
  }

  Widget _buildClustersOverview() {
    return ListView.builder(
        itemCount: _data.clusters.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          return _buildRow(_data.clusters[i]);
        });
  }

  Widget _buildRow(Cluster cluster) {
    return GestureDetector(
      child: ListTile(
        title: Text(
          cluster.name,
        ),
        leading: IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            _showCluster(cluster);
          },
        ),
        trailing: IconButton(
          icon: Icon(
            cluster.running ? Icons.pause : Icons.play_arrow,
            color: cluster.statusColor(),
            size: 30,
          ),
          onPressed: () {
            if (cluster.running) return;
            dev.log("Play : $cluster");
            cluster.run(_data.sshKey).then((v) {
              setState(() {});
            });
            setState(() {});
          },
        ),
        onTap: () {
          _showCluster(cluster);
        },
      ),
      onLongPressStart: (LongPressStartDetails details) {
        _showClusterMenu(details.globalPosition, cluster);
      },
    );
  }

  void _showCluster(Cluster cluster) async {
    dev.log("_showCluster : $cluster");
    final Cluster result = await Navigator.of(context).push(MaterialPageRoute<Cluster>(builder: (BuildContext context) {
      return ClusterView(_data.sshKey, cluster);
    }));
    if (result != null) {
      dev.log("_showCluster : Updating $cluster");
      _db.addCluster(result);
      setState(() {});
    }
  }

  // https://stackoverflow.com/a/53861303
  void _clustersMenu() async {
    final Cluster result = await Navigator.of(context).push(
      MaterialPageRoute<Cluster>(
        builder: (BuildContext context) {
          return ClusterView.newCluster(_data.sshKey, _data.clusters.length);
        },
      ),
    );

    setState(() {
      if (result != null) {
        dev.log("Adding $result");
        _data.clusters.add(result);
        _db.addCluster(result);
      }
    });
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
      _db.setSSHKey(_data.sshKey);
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
    _data = await Navigator.of(context).push(
      MaterialPageRoute<ClusterUpData>(
        builder: (BuildContext context) {
          return LoadSaveView(_data);
        },
      ),
    );

    if (_data != null) {
      setState(() {
        _db.setClusters(_data.clusters);
        _db.setSSHKey(_data.sshKey);
      });
    }
  }

  void _aboutMenu() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Cluster up"),
            content: Text("Control health of your servers"),
          );
        });
  }

  void _showClusterMenu(Offset position, Cluster cluster) async {
    var itemRemove = PopupMenuItem(
      child: Text("Remove"),
      value: ClusterOpts.Remove,
    );

    var itemLastRun = PopupMenuItem(
      child: Text("Show last run"),
      value: ClusterOpts.LastRun,
    );

    var selected = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, 200, 200),
      items: [itemLastRun, itemRemove],
    );

    switch (selected) {
      case ClusterOpts.Remove:
        setState(() {
          dev.log("Removing $cluster");
          _data.clusters.remove(cluster);
          _db.removeCluster(cluster);
        });
        break;
      case ClusterOpts.LastRun:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) {
          return ResultsView(null, cluster, false);
        }));
        break;
    }
  }

  PopupMenuButton<ClustersOpts> _buildClustersPopUpButton() {
    String keyText = (_data.sshKey != null) ? "View SSH Key" : "Generate SSH Key";
    return PopupMenuButton<ClustersOpts>(
      onSelected: (ClustersOpts result) {
        switch (result) {
          case ClustersOpts.NewCluster:
            {
              dev.log("NewCluster");
              _clustersMenu();
            }
            break;
          case ClustersOpts.Key:
            {
              dev.log("Key");
              _keyMenu();
            }
            break;
          case ClustersOpts.Actions:
            {
              dev.log("Key");
              _actionsMenu();
            }
            break;
          case ClustersOpts.LoadSave:
            {
              dev.log("Load/Save");
              _loadSaveMenu();
            }
            break;
          case ClustersOpts.About:
            {
              dev.log("About");
              _aboutMenu();
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ClustersOpts>>[
        const PopupMenuItem<ClustersOpts>(
          value: ClustersOpts.NewCluster,
          child: Text('Add new cluster'),
        ),
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
      body: _buildClustersOverview(),
    );
  }
}

enum ClustersOpts { NewCluster, Key, Actions, LoadSave, About }
enum ClusterOpts { Remove, LastRun }

class ClustersView extends StatefulWidget {
  @override
  ClustersViewState createState() => ClustersViewState();
}
