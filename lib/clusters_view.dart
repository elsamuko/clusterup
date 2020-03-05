import 'package:clusterup/remote_actions_view.dart';
import 'package:clusterup/persistence.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'cluster.dart';
import 'cluster_view.dart';
import 'key_view.dart';
import 'ssh_key.dart';
import 'remote_action.dart';

class ClustersState extends State<Clusters> {
  Persistence _db = Persistence();
  List<Cluster> _clusters = [];
  SSHKey _sshKey;

  @override
  void initState() {
    _db.getSSHKey().then((sshKey) {
      _sshKey = sshKey;
      setState(() {});
    });

    _db.readClusters().then((clusters) {
      _clusters = clusters;
      setState(() {});
    });
    super.initState();
  }

  Widget _buildClustersOverview() {
    return ListView.builder(
        itemCount: _clusters.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          return _buildRow(_clusters[i]);
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
            Icons.play_arrow,
            color: Colors.blue,
          ),
          onPressed: () {
            dev.log("Play : ${cluster}");
          },
        ),
        onTap: () {
          dev.log("Tap : ${cluster}");
        },
      ),
      onLongPressStart: (LongPressStartDetails details) {
        _showClusterMenu(details.globalPosition, cluster);
      },
    );
  }

  void _showCluster(Cluster cluster) async {
    dev.log("_showCluster : ${cluster}");
    final Cluster result = await Navigator.of(context)
        .push(MaterialPageRoute<Cluster>(builder: (BuildContext context) {
      return ClusterView(_sshKey, cluster);
    }));
    if (result != null) {
      _db.addCluster(result);
    }
  }

  // https://stackoverflow.com/a/53861303
  void _clustersMenu() async {
    final Cluster result = await Navigator.of(context).push(
      MaterialPageRoute<Cluster>(
        builder: (BuildContext context) {
          return ClusterView.newCluster(_sshKey, _clusters.length);
        },
      ),
    );

    setState(() {
      if (result != null) {
        dev.log("Adding ${result}");
        _clusters.add(result);
        _db.addCluster(result);
      }
    });
  }

  void _keyMenu() async {
    _sshKey = await Navigator.of(context).push(
      MaterialPageRoute<SSHKey>(
        builder: (BuildContext context) {
          return KeyView(_sshKey);
        },
      ),
    );

    if (_sshKey != null) {
      _db.setSSHKey(_sshKey);
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

  void _showClusterMenu(Offset position, Cluster cluster) async {
    var itemRemove = PopupMenuItem(
      child: Text("Remove"),
      value: ClusterOpts.Remove,
    );

    var selected = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, 200, 200),
      items: [itemRemove],
    );

    if (selected == ClusterOpts.Remove) {
      setState(() {
        dev.log("Removing ${cluster}");
        _clusters.remove(cluster);
        _db.removeCluster(cluster);
      });
    }
  }

  PopupMenuButton<ClustersOpts> _buildClustersPopUpButton() {
    String keyText = (_sshKey != null) ? "View SSH Key" : "Generate SSH Key";
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
          case ClustersOpts.About:
            {
              dev.log("About");
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

enum ClustersOpts { NewCluster, Key, Actions, About }
enum ClusterOpts { Remove }

class Clusters extends StatefulWidget {
  @override
  ClustersState createState() => ClustersState();
}
