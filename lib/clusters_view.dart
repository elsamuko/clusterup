import 'package:clusterup/persistence.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'cluster.dart';
import 'cluster_view.dart';
import 'key_view.dart';
import 'ssh_key.dart';

class ClustersState extends State<Clusters> {
  Persistence _db = Persistence();
  List<Cluster> _clusters = [];
  SSHKey _sshKey;

  @override
  void initState() {
    _db.readClusters().then((result) {
      _clusters = result;
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
    return ListTile(
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
          dev.log("_buildRow play : ${cluster}");
        },
      ),
      onTap: () {
        dev.log("play : ${cluster}");
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

enum ClustersOpts { NewCluster, Key, About }

class Clusters extends StatefulWidget {
  @override
  ClustersState createState() => ClustersState();
}
