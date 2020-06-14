import 'dart:developer' as dev;
import 'package:clusterup/remote_action.dart';
import 'package:clusterup/views/result_details_view.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import '../cluster.dart';

class ClusterChildrenResultsViewState extends State<ClusterChildrenResultsView> {
  SSHKey _key;
  bool _run = false;
  Cluster _cluster;
  RemoteAction current;

  ClusterChildrenResultsViewState(this._key, this._cluster, this._run);

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
      _cluster.onActionFinished = (RemoteActionPair pair) {
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

  void _showResultDetails(RemoteActionPair pair) async {
    dev.log("_showResultDetails : $pair");
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return ResultDetailsView(pair);
    }));
  }

  Widget _buildRow(RemoteActionPair pair) {
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
          style: TextStyle(color: unknowns > 0 ? Colors.white : Colors.grey, fontWeight: unknowns > 0 ? FontWeight.bold : FontWeight.normal),
        ),
        SizedBox(width: 10),
        Text(
          successes.toString(),
          style: TextStyle(color: successes > 0 ? Colors.greenAccent : Colors.green, fontWeight: successes > 0 ? FontWeight.bold : FontWeight.normal),
        ),
        SizedBox(width: 10),
        Text(
          warnings.toString(),
          style: TextStyle(color: warnings > 0 ? Colors.orangeAccent : Colors.orange, fontWeight: warnings > 0 ? FontWeight.bold : FontWeight.normal),
        ),
        SizedBox(width: 10),
        Text(
          errors.toString(),
          style: TextStyle(color: errors > 0 ? Colors.redAccent : Colors.red, fontWeight: errors > 0 ? FontWeight.bold : FontWeight.normal),
        ),
      ]);
    }
    return ListTile(
      onTap: () {
        _showResultDetails(pair);
      },
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
            itemCount: _cluster.results.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, i) {
              return _buildRow(_cluster.results.elementAt(i));
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
