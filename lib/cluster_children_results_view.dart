import 'package:clusterup/cluster_child.dart';
import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import 'ssh_connection.dart';
import 'cluster.dart';

class ClusterChildrenResultsViewState extends State<ClusterChildrenResultsView> {
  SSHKey _key;
  bool _run = false;
  Cluster _cluster;
  List<RemoteActionPair> actions; // finished actions
  RemoteAction current;

  ClusterChildrenResultsViewState(this._key, this._cluster, this._run);

  Future<List<SSHConnectionResult>> testSSH() async {
    List<SSHConnectionResult> results = [];
    for (ClusterChild child in _cluster.children) {
      results.add(await SSHConnection.test(child.creds(), _key));
    }
    return results;
  }

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
      _cluster.onActionFinished = (RemoteActionPair pair) {
        setState(() {
          current = null;
        });
      };

      // run
      testSSH().then((List<SSHConnectionResult> results) {
        current = null;
        setState(() {
          results.forEach((SSHConnectionResult result) {
            if (result.success) {
              actions.first.results.add(RemoteActionResult.success());
            } else {
              actions.first.results.add(RemoteActionResult.error(result.error));
            }
          });
          _cluster.runChildren(_key);
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

    int unknowns = pair.results.where((RemoteActionResult result) => result.unknown()).length;
    int successes = pair.results.where((RemoteActionResult result) => result.success()).length;
    int warnings = pair.results.where((RemoteActionResult result) => result.warning()).length;
    int errors = pair.results.where((RemoteActionResult result) => result.error()).length;

    if (!running) {
      indicator = Row(children: <Widget>[
        Text(
          unknowns.toString(),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(width: 10),
        Text(
          successes.toString(),
          style: TextStyle(color: Colors.green),
        ),
        SizedBox(width: 10),
        Text(
          warnings.toString(),
          style: TextStyle(color: Colors.orange),
        ),
        SizedBox(width: 10),
        Text(
          errors.toString(),
          style: TextStyle(color: Colors.red),
        ),
      ]);
    }
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(child: Text(pair.action.name)),
          indicator,
        ],
      ),
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

class ClusterChildrenResultsView extends StatefulWidget {
  final SSHKey _key;
  final Cluster _cluster;
  final bool _run;

  ClusterChildrenResultsView(this._key, this._cluster, this._run);

  @override
  ClusterChildrenResultsViewState createState() => ClusterChildrenResultsViewState(this._key, this._cluster, this._run);
}
