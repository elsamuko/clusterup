import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'cluster.dart';
import 'newcluster.dart';

void main() => runApp(MyApp());

// https://flutter.dev/docs/get-started/codelab
// https://codelabs.developers.google.com/codelabs/first-flutter-app-pt2/#0
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cluster Up',
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: Scaffold(
        body: Center(
          child: Clusters(),
        ),
      ),
    );
  }
}

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

  void _clustersMenu() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return NewCluster();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clusters'),
        actions: <Widget>[
          PopupMenuButton<ClusterOpts>(
            onSelected: (ClusterOpts result) {
              switch( result ) {
                case ClusterOpts.NewCluster: {
                  dev.log("NewCluster");
                  _clustersMenu();
                } break;
                case ClusterOpts.About: {
                  dev.log("About");
                } break;
              }
              },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ClusterOpts>>[
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
