import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import '../remote_action.dart';

class ResultDetailsViewState extends State<ResultDetailsView> {
  RemoteActionPair pair;

  ResultDetailsViewState(this.pair);

  Widget _buildRow(RemoteActionResult result) {
    TextStyle style;
    var indicator;

    switch (result.status) {
      case RemoteActionStatus.Unknown:
        style = TextStyle(color: Colors.white);
        indicator = Text("-");
        break;
      case RemoteActionStatus.Success:
        style = TextStyle(color: Colors.greenAccent);
        indicator = Icon(Icons.check_circle, color: Colors.green[300]);
        break;
      case RemoteActionStatus.Warning:
        style = TextStyle(color: Colors.orangeAccent);
        indicator = Icon(Icons.warning, color: Colors.orange[300]);
        break;
      case RemoteActionStatus.Error:
        style = TextStyle(color: Colors.redAccent);
        indicator = Icon(Icons.error, color: Colors.red[300]);
        break;
      default:
        style = TextStyle(color: Colors.white);
    }

    return ListTile(
      subtitle: Text(result.filtered),
      title: Text(result.from, style: style),
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
          title: Text("Details for ${pair.action.name}"),
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
