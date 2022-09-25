import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import '../cluster.dart';
import '../widgets/result_card.dart';

class ClusterResultsViewState extends State<ClusterResultsView> {
  Cluster _cluster;
  RemoteAction? current;
  ScrollController _scrollController = ScrollController();

  ClusterResultsViewState(this._cluster);

  @override
  void initState() {
    current = widget._cluster.lastAction();

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
    if (widget._cluster.running) {
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
          title: Text(_cluster.running ? "Running on ${_cluster.name}" : "Last run on ${_cluster.name}"),
        ),
        body: body);
  }
}

class ClusterResultsView extends StatefulWidget {
  Cluster _cluster;

  ClusterResultsView(this._cluster);

  @override
  ClusterResultsViewState createState() => ClusterResultsViewState(this._cluster);
}
