import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';

class ActionsViewState extends State<ActionsView> {
  ActionsViewState();

  Widget _buildRow(RemoteAction action) {
    final bool marked = widget._saved.contains(action);
    IconButton leading = widget._selectable
        ? IconButton(
            icon:
                Icon(marked ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: () {
              setState(() {
                if (marked) {
                  widget._saved.remove(action);
                } else {
                  widget._saved.add(action);
                }
              });
            })
        : IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(action.name),
                      content: Text(action.description),
                    );
                  });
            });

    return ListTile(
      title: Text(action.name),
      subtitle: Text(action.description),
      leading: leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = widget._selectable ? "Select Actions" : "Available Actions";
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, widget._saved);
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context, widget._saved);
                },
              ),
              title: Text(title),
            ),
            body: ListView.builder(
                itemCount: widget._actions.length,
                padding: const EdgeInsets.all(16.0),
                itemBuilder: (context, i) {
                  return _buildRow(widget._actions.elementAt(i));
                })));
  }
}

class ActionsView extends StatefulWidget {
  final Set<RemoteAction> _actions = RemoteAction.allActions();
  Set<RemoteAction> _saved;
  bool _selectable = false;

  ActionsView({Set<RemoteAction> saved}) {
    if (saved != null) {
      _selectable = true;
      _saved = saved;
    } else {
      _saved = Set<RemoteAction>();
    }
  }

  @override
  ActionsViewState createState() => ActionsViewState();
}
