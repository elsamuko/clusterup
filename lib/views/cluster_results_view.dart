import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:flutter/widgets.dart';
import '../cluster.dart';
import '../widgets/result_card.dart';

class ClusterResultsViewState extends State<ClusterResultsView> {
  SSHKey _key;
  bool _run = false;
  Cluster _cluster;
  RemoteAction current;
  ScrollController _scrollController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    Scrollbar body = Scrollbar(
        child: ListView.builder(
            controller: _scrollController,
            itemCount: _cluster.results.length,
            itemBuilder: (context, i) {
              RemoteActionPair pair = _cluster.results.elementAt(i);
              bool running = pair.action == current;
              return ResultCard(_cluster.results.elementAt(i), running);
            }));

    // scroll to bottom when running live
    if (_run) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      });
    }

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            key: Key("back"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(_run ? "Running on ${_cluster.name}" : "Last run on ${_cluster.name}"),
        ),
        body: body);
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
