import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'cluster.dart';
import 'cluster_view.dart';
import 'key_view.dart';
import 'ssh_key.dart';

class ClustersState extends State<Clusters> {
  List<Cluster> _clusters = Cluster.generateClusters();
  SSHKey _sshKey;

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
      return ClusterView(cluster);
    }));
  }

  // https://stackoverflow.com/a/53861303
  void _clustersMenu() async {
    final Cluster result = await Navigator.of(context).push(
      MaterialPageRoute<Cluster>(
        builder: (BuildContext context) {
          return ClusterView();
        },
      ),
    );

    setState(() {
      if (result != null) {
        dev.log("Adding ${result}");
        _clusters.add(result);
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

  @override
  Widget build(BuildContext context) {
    String keyText = (_sshKey != null) ? "View SSH Key" : "Generate SSH Key";
    return Scaffold(
      appBar: AppBar(
        title: Text('Clusters'),
        actions: <Widget>[
          PopupMenuButton<ClusterOpts>(
            onSelected: (ClusterOpts result) {
              switch (result) {
                case ClusterOpts.NewCluster:
                  {
                    dev.log("NewCluster");
                    _clustersMenu();
                  }
                  break;
                case ClusterOpts.Key:
                  {
                    dev.log("Key");
                    _keyMenu();
                  }
                  break;
                case ClusterOpts.About:
                  {
                    dev.log("About");
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<ClusterOpts>>[
              const PopupMenuItem<ClusterOpts>(
                value: ClusterOpts.NewCluster,
                child: Text('Add new cluster'),
              ),
              PopupMenuItem<ClusterOpts>(
                value: ClusterOpts.Key,
                child: Text(keyText),
              ),
              const PopupMenuItem<ClusterOpts>(
                value: ClusterOpts.About,
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),
      body: _buildClustersOverview(),
    );
  }
}

enum ClusterOpts { NewCluster, Key, About }

class Clusters extends StatefulWidget {
  @override
  ClustersState createState() => ClustersState();
}
