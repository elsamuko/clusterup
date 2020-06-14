import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import '../cluster.dart';

class ClusterResultsViewState extends State<ClusterResultsView> {
  SSHKey _key;
  bool _run = false;
  Cluster _cluster;
  RemoteAction current;

  ClusterResultsViewState(this._key, this._cluster, this._run);

  @override
  void initState() {
    if (_run) {
      // set callback for results
      _cluster.onActionStarted = (RemoteActionPair pair) {
        setState(() {
          current = pair.action;
        });
      };

      // set callback for results
      _cluster.onActionFinished = (RemoteActionPair action) {
        setState(() {
          current = null;
        });
      };

      // run
      _cluster.run(_key);
    }

    super.initState();
  }

  @override
  void dispose() {
    _cluster.onActionStarted = (_) {};
    _cluster.onActionFinished = (_) {};
    super.dispose();
  }

  Widget _buildRow(RemoteActionPair pair) {
    RemoteActionResult result = pair.results.isNotEmpty ? pair.results.first : RemoteActionResult.unknown();
    bool running = pair.action == current;
    var indicator = running
        ? SizedBox(
            child: CircularProgressIndicator(),
            height: 15.0,
            width: 15.0,
          )
        : Icon(Icons.done);

    if (!running) {
      switch (result.status) {
        case RemoteActionStatus.Unknown:
          indicator = Text("-");
          break;
        case RemoteActionStatus.Success:
          indicator = Icon(Icons.check_circle, color: Colors.green[300]);
          break;
        case RemoteActionStatus.Warning:
          indicator = Icon(Icons.warning, color: Colors.orange[300]);
          break;
        case RemoteActionStatus.Error:
          indicator = Icon(Icons.error, color: Colors.red[300]);
          break;
      }
    }
    return ListTile(
      title: Text(pair.action.name),
      subtitle: Text(result.filtered),
      trailing: indicator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(_run ? "Running on ${_cluster.name}" : "Last run on ${_cluster.name}"),
        ),
        body: ListView.builder(
            itemCount: _cluster.results.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, i) {
              return _buildRow(_cluster.results.elementAt(i));
            }));
  }
}

class ClusterResultsView extends StatefulWidget {
  SSHKey _key;
  Cluster _cluster;
  bool _run = false;

  ClusterResultsView(this._key, this._cluster, this._run);

  @override
  ClusterResultsViewState createState() => ClusterResultsViewState(this._key, this._cluster, this._run);
}
