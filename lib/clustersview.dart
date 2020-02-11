import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'cluster.dart';
import 'newcluster.dart';

class ClustersState extends State<Clusters> {
  final _clusters = Cluster.generateClusters();
  final List<Cluster> _saved = List<Cluster>();
  ClusterOpts _selection;

  Widget _buildClustersOverview() {
    return ListView.builder(
        itemCount: _clusters.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          return _buildRow(_clusters[i]);
        });
  }

  Widget _buildRow(Cluster cluster) {
    final bool alreadySaved = _saved.contains(cluster);
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
        setState(() {
          if (alreadySaved) {
            _saved.remove(cluster);
          } else {
            _saved.add(cluster);
          }
        });
      },
    );
  }

  void _showCluster(Cluster cluster) {
    dev.log("_showCluster : ${cluster}");
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cluster ${cluster}'),
        ),
        body: Center(child: Text('Details of ${cluster}')),
      );
    }));
  }

  // https://stackoverflow.com/a/53861303
  void _clustersMenu() async {
    final Cluster result = await Navigator.of(context).push(
      MaterialPageRoute<Cluster>(
        builder: (BuildContext context) {
          return NewCluster();
        },
      ),
    );

    setState(() {
      if(result != null) {
        dev.log("Adding ${result}");
        _clusters.add(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

enum ClusterOpts { NewCluster, About }

class Clusters extends StatefulWidget {
  @override
  ClustersState createState() => ClustersState();
}
