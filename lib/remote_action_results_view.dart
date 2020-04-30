import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import 'cluster.dart';

class ResultsViewState extends State<ResultsView> {
  SSHKey _key;
  bool _run = false;
  Cluster _cluster;
  List<RemoteAction> actions; // finished actions
  RemoteAction current;

  ResultsViewState(this._key, this._cluster, this._run);

  @override
  void initState() {
    if (_run) {
      actions = [];

      // set callback for results
      _cluster.onActionStarted = (RemoteAction action) {
        setState(() {
          current = action;
          actions.add(action);
        });
      };

      // set callback for results
      _cluster.onActionFinished = (RemoteAction action) {
        setState(() {
          current = null;
        });
      };

      // run
      _cluster.run(_key);
    } else {
      actions = this._cluster.actions.toList();
    }
  }

  Widget _buildRow(RemoteAction action) {
    bool running = action == current;
    Icon icon = Icon(running ? Icons.all_inclusive : Icons.done);

    if (!running) {
      switch (action.status) {
        case RemoteActionStatus.Unknown:
          icon = Icon(Icons.done, color: Colors.white);
          break;
        case RemoteActionStatus.Success:
          icon = Icon(Icons.check_circle, color: Colors.green[300]);
          break;
        case RemoteActionStatus.Warning:
          icon = Icon(Icons.warning, color: Colors.orange[300]);
          break;
        case RemoteActionStatus.Error:
          icon = Icon(Icons.error, color: Colors.red[300]);
          break;
      }
    }
    return ListTile(
      title: Text(action.name),
      subtitle: Text(action.filtered),
      trailing: icon,
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
            itemCount: actions.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, i) {
              return _buildRow(actions.elementAt(i));
            }));
  }
}

class ResultsView extends StatefulWidget {
  SSHKey _key;
  Cluster _cluster;
  bool _run = false;

  ResultsView(this._key, this._cluster, this._run);

  @override
  ResultsViewState createState() => ResultsViewState(this._key, this._cluster, this._run);
}
