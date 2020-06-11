import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import 'ssh_connection.dart';
import 'cluster.dart';

class ClusterResultsViewState extends State<ClusterResultsView> {
  SSHKey _key;
  bool _run = false;
  Cluster _cluster;
  List<RemoteActionPair> actions; // finished actions
  RemoteAction current;

  ClusterResultsViewState(this._key, this._cluster, this._run);

  @override
  void initState() {
    if (_run) {
      actions = [RemoteActionPair(RemoteAction.getHostUpAction())];
      current = actions.first.action;

      // set callback for results
      _cluster.onActionStarted = (RemoteActionPair pair) {
        setState(() {
          current = pair.action;
          actions.add(pair);
        });
      };

      // set callback for results
      _cluster.onActionFinished = (RemoteActionPair action) {
        setState(() {
          current = null;
        });
      };

      // run
      SSHConnection.test(_cluster.creds(), _key).then((SSHConnectionResult result) {
        current = null;
        setState(() {
          if (result.success) {
            actions.first.results.add(RemoteActionResult.success());
            _cluster.run(_key);
          } else {
            actions.first.results.add(RemoteActionResult.error(result.error));
          }
        });
      });
    } else {
      actions = this._cluster.actions.map((action) {
        return RemoteActionPair(action);
      });
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
            itemCount: actions.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, i) {
              return _buildRow(actions.elementAt(i));
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
