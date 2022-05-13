import 'package:flutter/material.dart';
import '../remote_action.dart';

class ResultCard extends StatelessWidget {
  final bool running;
  final RemoteActionPair pair;

  const ResultCard(this.pair, this.running, {Key key}) : super(key: key);

  Widget indicator(RemoteActionPair pair) {
    Widget indicator;

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
          indicator = Icon(Icons.check_circle, color: Colors.green[300], size: 24);
          break;
        case RemoteActionStatus.Warning:
          indicator = Icon(Icons.warning, color: Colors.orange[300], size: 24);
          break;
        case RemoteActionStatus.Error:
          indicator = Icon(Icons.error, color: Colors.red[300], size: 24);
          break;
      }
    }
    return indicator;
  }

  Widget _buildResult(RemoteActionResult result) {
    TextStyle style;
    switch (result.status) {
      case RemoteActionStatus.Unknown:
        style = TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );
        break;
      case RemoteActionStatus.Success:
        style = TextStyle(
          color: Colors.greenAccent,
          fontWeight: FontWeight.w600,
        );
        break;
      case RemoteActionStatus.Warning:
        style = TextStyle(
          color: Colors.orangeAccent,
          fontWeight: FontWeight.w500,
        );
        break;
      case RemoteActionStatus.Error:
        style = TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        );
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
          child: Row(children: <Widget>[
            SizedBox(width: 4),
            Expanded(
              child: Container(
                padding: EdgeInsets.fromLTRB(8, 2, 4, 2),
                color: Color(0xff393939),
                child: Text(
                  result.filtered,
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontFamily: "monospace",
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: 6)
          ])));
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
        child: Row(children: <Widget>[
          Expanded(
              child: Text(
            pair.action.name,
            style: TextStyle(fontSize: 16),
          )),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: indicator(pair),
          ),
        ]),
      ),
      ListView.separated(
          separatorBuilder: (context, index) => Divider(height: 12),
          itemCount: pair.results.length,
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemBuilder: (context, i) {
            return _buildResult(pair.results.elementAt(i));
          }),
      SizedBox(height: 8),
    ];

    return Card(
      elevation: 6,
      child: Column(children: children),
    );
  }
}
