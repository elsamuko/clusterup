import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  DBPersistence _db = DBPersistence();
  ClusterUpData _data = ClusterUpData();

  @override
  void initState() {
    _db.getSSHKey().then((sshKey) {
      _data.sshKey = sshKey;
      log("Loaded ssh key");
      setState(() {});
    });

    _db.readClusters().then((clusters) {
      log("Loaded ${clusters.length} clusters");
      _data.clusters = clusters;
      setState(() {});
    });
    super.initState();
  }

  Widget _buildClustersOverview() {
    return ListView.builder(
        itemCount: _data.clusters.length,
        padding: const EdgeInsets.all(8.0),
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
              log("Play : $cluster");
              cluster.run(_data.sshKey).then((v) {
                setState(() {});
              });
              setState(() {});
            },
          );

    return GestureDetector(
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(top: 3.0),
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
          child: Text(
            cluster.name,
          ),
          scrollDirection: Axis.horizontal,
        ),
        trailing: trailing,
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
    log("_showCluster : $cluster");
    cluster.persist = () => _db.addCluster(cluster);
    final Cluster result = await Navigator.of(context).push(MaterialPageRoute<Cluster>(builder: (BuildContext context) {
      return ClusterView(_data.sshKey, cluster);
    }));
    if (result != null) {
      log("_showCluster : Updating $cluster");
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
        log("Adding $result");
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
      enabled: cluster.results.isNotEmpty,
    );

    var selected = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, 200, 200),
      items: [itemLastRun, itemRemove],
    );

    switch (selected) {
      case ClusterOpts.Remove:
        setState(() {
          log("Removing $cluster");
          _data.clusters.remove(cluster);
          _db.removeCluster(cluster);
        });
        break;
      case ClusterOpts.LastRun:
        _showLastRun(cluster);
        break;
    }
  }

  void _showLastRun(Cluster cluster) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return ClusterResultsView(null, cluster, false);
    }));
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
