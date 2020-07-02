import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:flutter/widgets.dart';
import '../cluster.dart';

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

  Widget _buildResult(RemoteActionResult result) {
    TextStyle style;
    switch (result.status) {
      case RemoteActionStatus.Unknown:
        style = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
        break;
      case RemoteActionStatus.Success:
        style = TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600);
        break;
      case RemoteActionStatus.Warning:
        style = TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600);
        break;
      case RemoteActionStatus.Error:
        style = TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600);
        break;
    }

    Row creds = Row(
      children: <Widget>[
        Text("${result.from.user}@", style: TextStyle(color: Color(0xffa1a1a1))),
        Text(result.from.host, style: style),
        Text(":${result.from.port}", style: TextStyle(color: Color(0xffa1a1a1))),
      ],
    );

    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 2, 2),
        child: creds,
      )
    ];
    if (result.filtered.isNotEmpty) {
      children.add(SizedBox(height: 2));
      children.add(Padding(
        padding: const EdgeInsets.all(2.0),
        child: Text(result.filtered),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget indicator(RemoteActionPair pair) {
    Widget indicator;
    bool running = pair.action == current;

    if (running) {
      indicator = SizedBox(
        child: CircularProgressIndicator(),
        height: 15.0,
        width: 15.0,
      );
    } else {
      RemoteActionStatus worst = pair.results.fold(RemoteActionStatus.Unknown, (value, element) {
        if (value.index < element.status.index) {
          return element.status;
        } else {
          return value;
        }
      });

      switch (worst) {
        case RemoteActionStatus.Unknown:
          indicator = Text("-");
          break;
        case RemoteActionStatus.Success:
          indicator = Icon(Icons.check_circle, color: Colors.green[300], size: 20);
          break;
        case RemoteActionStatus.Warning:
          indicator = Icon(Icons.warning, color: Colors.orange[300], size: 20);
          break;
        case RemoteActionStatus.Error:
          indicator = Icon(Icons.error, color: Colors.red[300], size: 20);
          break;
        default:
          indicator = Text("-");
      }
    }
    return indicator;
  }

  Widget _buildRow(RemoteActionPair pair) {
    List<Widget> children = <Widget>[
      ListTile(
        title: Row(children: <Widget>[
          Expanded(child: Text(pair.action.name)),
          indicator(pair),
        ]),
      ),
      ListView.separated(
          separatorBuilder: (context, index) => Divider(height: 5),
          itemCount: pair.results.length,
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemBuilder: (context, i) {
            return _buildResult(pair.results.elementAt(i));
          }),
      SizedBox(height: 4),
    ];

    return Card(
      elevation: 6,
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    Scrollbar body = Scrollbar(
        child: ListView.builder(
            controller: _scrollController,
            itemCount: _cluster.results.length,
            itemBuilder: (context, i) {
              return _buildRow(_cluster.results.elementAt(i));
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
