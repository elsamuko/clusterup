import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import '../remote_action.dart';

class ResultDetailsViewState extends State<ResultDetailsView> {
  RemoteActionPair pair;

  ResultDetailsViewState(this.pair);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildRow(RemoteActionResult result) {
    Function colorFor = (RemoteActionStatus status) {
      switch (status) {
        case RemoteActionStatus.Unknown:
          return TextStyle(color: Colors.white);
        case RemoteActionStatus.Success:
          return TextStyle(color: Colors.greenAccent);
        case RemoteActionStatus.Warning:
          return TextStyle(color: Colors.orangeAccent);
        case RemoteActionStatus.Error:
          return TextStyle(color: Colors.redAccent);
        default:
          return TextStyle(color: Colors.white);
      }
    };

    return ListTile(
      subtitle: Text(result.filtered),
      title: Text(result.from, style: colorFor(result.status)),
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
          title: Text("Details for action ${pair.action.name}"),
        ),
        body: ListView.builder(
            itemCount: pair.results.length,
            padding: const EdgeInsets.only(left: 8.0),
            itemBuilder: (context, i) {
              return _buildRow(pair.results.elementAt(i));
            }));
  }
}

class ResultDetailsView extends StatefulWidget {
  RemoteActionPair pair;

  ResultDetailsView(this.pair);

  @override
  ResultDetailsViewState createState() => ResultDetailsViewState(this.pair);
}
