import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clusterup/log.dart';
import 'cluster_child_view.dart';
import 'cluster_results_view.dart';
import 'remote_actions_view.dart';
import '../ssh_key.dart';
import '../cluster_child.dart';
import '../ssh_connection.dart';
import '../cluster.dart';
import '../remote_action.dart';

class ClusterViewState extends State<ClusterView> {
  ClusterViewState();

  final _formKey = GlobalKey<FormState>();
  bool testingConnection = false;

  @override
  void initState() {
    widget._cluster.onRunningFinished = () {
      setState(() {});
    };
    super.initState();
  }

  @override
  void dispose() {
    widget._cluster.onRunningFinished = () {};
    super.dispose();
  }

  void validate() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      widget._cluster.persist();
    }
  }

  void _testSSH() async {
    if (testingConnection) {
      log("Already running");
      return;
    }

    log("Testing ${widget._cluster}");
    setState(() {
      testingConnection = true;
    });

    SSHConnectionResult result = await SSHConnection.test(widget._cluster.creds(), widget._key);

    String text = result.success ? "SSH connection successful!" : "SSH connection failed : ${result.error}";
    final snackBar = SnackBar(content: Text(text));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    setState(() {
      testingConnection = false;
    });
  }

  void _showClusterChild(ClusterChild child) async {
    log("_showClusterChild : $child");
    final ClusterChild result =
        await Navigator.of(context).push(MaterialPageRoute<ClusterChild>(builder: (BuildContext context) {
      return ClusterChildView(widget._key, child);
    }));
    if (result != null) {
      log("_showCluster : Updating $child");
      setState(() {
        widget._cluster.persist();
      });
    }
  }

  void addChild() async {
    final ClusterChild result = await Navigator.of(context).push(
      MaterialPageRoute<ClusterChild>(
        builder: (BuildContext context) {
          return ClusterChildView.newClusterChild(widget._key, widget._cluster);
        },
      ),
    );

    setState(() {
      if (result != null) {
        log("Adding $result");
        widget._cluster.children.add(result);
        widget._cluster.persist();
      }
    });
  }

  Widget _buildClusterChildren() {
    return Card(
        elevation: 6,
        child: ListView.builder(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          itemCount: widget._cluster.children.length,
          itemBuilder: (context, i) {
            return _buildChildRow(widget._cluster.children[i]);
          },
        ));
  }

  Widget _buildChildRow(ClusterChild child) {
    Function amberIf = (bool cond) {
      return TextStyle(color: cond ? Color(0xffa1a1a1) : Colors.amberAccent);
    };

    Row creds = Row(
      children: <Widget>[
        Text(child.user ?? child.parent.user, style: amberIf(child.user == null)),
        Text("@", style: TextStyle(color: Color(0xffa1a1a1))),
        Text(child.host ?? child.parent.host, style: amberIf(child.host == null)),
        Text(":", style: TextStyle(color: Color(0xffa1a1a1))),
        Text((child.port ?? child.parent.port).toString(), style: amberIf(child.port == null)),
      ],
    );

    Row row = Row(
      children: <Widget>[
        SizedBox(width: 4),
        Icon(
          Icons.child_care,
          size: 18,
          color: Color(0xffc7c7c7),
        ),
        SizedBox(width: 18),
        Expanded(
          child: SingleChildScrollView(
            child: creds,
            scrollDirection: Axis.horizontal,
          ),
        ),
      ],
    );

    return GestureDetector(
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 8),
        title: row,
        trailing: Checkbox(
            activeColor: Colors.grey,
            value: child.enabled,
            onChanged: (bool enabled) {
              setState(() {
                child.enabled = enabled;
                widget._cluster.persist();
              });
            }),
        onTap: () {
          _showClusterChild(child);
        },
      ),
      onLongPressStart: (LongPressStartDetails details) {
        _showClusterChildMenu(details.globalPosition, child);
      },
    );
  }

  void _showClusterChildMenu(Offset position, ClusterChild child) async {
    var itemRemove = PopupMenuItem(
      child: Text("Remove"),
      value: ClusterChildOpts.Remove,
    );

    var selected = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, 200, 200),
      items: [itemRemove],
    );

    switch (selected) {
      case ClusterChildOpts.Remove:
        setState(() {
          log("Removing $child");
          widget._cluster.children.remove(child);
          widget._cluster.persist();
        });
        break;
    }
  }

  PopupMenuButton<ClusterOpts> _buildClusterPopUpButton() {
    return PopupMenuButton<ClusterOpts>(
      onSelected: (ClusterOpts result) {
        switch (result) {
          case ClusterOpts.Actions:
            _showActions();
            break;
          case ClusterOpts.Test:
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();
              _testSSH();
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ClusterOpts>>[
        const PopupMenuItem<ClusterOpts>(
          value: ClusterOpts.Actions,
          child: Text("Actions"),
        ),
        PopupMenuItem<ClusterOpts>(
          value: ClusterOpts.Test,
          child: Text("Test"),
          enabled: !testingConnection,
        ),
      ],
    );
  }

  void _showActions() async {
    log("Configure Actions");
    Set<RemoteAction> selected = await Navigator.of(context).push(
      MaterialPageRoute<Set<RemoteAction>>(
        builder: (BuildContext context) {
          return ActionsView(saved: widget._cluster.actions);
        },
      ),
    );

    widget._cluster.actions = selected;
    widget._cluster.persist();
  }

  void _run() {
    if (!widget._cluster.running && _formKey.currentState.validate() && !testingConnection) {
      _formKey.currentState.save();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) {
        widget._cluster.run(widget._key);
        return ClusterResultsView(widget._cluster);
      })).then((_) {
        setState(() {});
      });
    }
  }

  void _showLastRun() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return ClusterResultsView(widget._cluster);
    }));
  }

  @override
  Widget build(BuildContext context) {
    log("NewClusterState");
    String title = "Edit cluster";
    List<Widget> checkButton = [_buildClusterPopUpButton()];

    if (widget._new) {
      title = "Add new cluster";
      checkButton.add(IconButton(
        key: Key("saveCluster"),
        icon: Icon(Icons.check_circle, size: 35, color: Colors.white),
        onPressed: () {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
            log("Saving new cluster ${widget._cluster}");
            Navigator.pop(context, widget._cluster);
          }
        },
      ));
    }

    var indicator = widget._cluster.running
        ? SizedBox(
            child: CircularProgressIndicator(),
            height: 15.0,
            width: 15.0,
          )
        : Text(
            "Run",
          );

    Row bottomButtons = Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
      TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[700],
            primary: Colors.white,
          ),
          onPressed: () async => _showLastRun(),
          child: Text(
            "Last run",
          )),
      TextButton(
          style: TextButton.styleFrom(
            backgroundColor: widget._cluster.running ? Color(0xff4d4d4d) : Color(0xffcc8d00),
            primary: Colors.white,
          ),
          onPressed: widget._cluster.running ? null : () async => _run(),
          key: Key("run"),
          child: indicator)
    ]);

    List<Widget> widgets = [_buildClusterCard()];
    if (widget._cluster.children.isNotEmpty) {
      widgets.add(_buildClusterChildren());
      widgets.add(SizedBox(height: 80));
    }

    return WillPopScope(
        onWillPop: () async {
          if (!widget._new && _formKey.currentState.validate()) {
            _formKey.currentState.save();
            Navigator.pop(context, widget._cluster);
            return false;
          } else {
            log("Abort new cluster");
            return true;
          }
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: checkButton,
            ),
            floatingActionButton: FloatingActionButton(
              key: Key("addChild"),
              backgroundColor: Color(0xff616161),
              foregroundColor: Color(0xffc7c7c7),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                }
                addChild();
              },
              child: const Icon(Icons.add),
            ),
            bottomNavigationBar: bottomButtons,
            body: Scrollbar(child: ListView(children: widgets))));
  }

  Widget _buildClusterCard() {
    return Card(
        elevation: 6,
        child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.label),
                        labelText: 'name',
                      ),
                      key: Key("name"),
                      onSaved: (String value) {
                        widget._cluster.name = value;
                      },
                      initialValue: widget._cluster?.name,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        hintText: 'username',
                        labelText: 'username',
                      ),
                      key: Key("username"),
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
                      onSaved: (String value) {
                        widget._cluster.user = value;
                      },
                      initialValue: widget._cluster?.user,
                      validator: (String value) {
                        return value.contains('@') ? 'Do not use the @ char.' : null;
                      },
                      onEditingComplete: validate,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.computer),
                        hintText: 'Server domain',
                        labelText: 'server',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
                      key: Key("server"),
                      onSaved: (String value) {
                        widget._cluster.host = value;
                      },
                      initialValue: widget._cluster?.host,
                      validator: (String value) {
                        return value.contains('@') ? 'Do not use the @ char.' : null;
                      },
                      onEditingComplete: validate,
                    ),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.local_airport),
                        hintText: 'SSH server port',
                        labelText: 'port',
                      ),
                      key: Key("port"),
                      onSaved: (String value) {
                        widget._cluster.port = int.parse(value);
                      },
                      initialValue: (widget._cluster?.port ?? 22).toString(),
                      validator: (String value) {
                        int port = int.tryParse(value);
                        if (port == null || port > 65535) {
                          return "Invalid port number";
                        } else {
                          return null;
                        }
                      },
                      onEditingComplete: validate,
                    ),
                  ],
                ))));
  }
}

enum ClusterOpts { Actions, Test }

enum ClusterChildOpts { Remove }

class ClusterView extends StatefulWidget {
  Cluster _cluster;
  SSHKey _key;
  bool _new = false;

  ClusterView(this._key, this._cluster);

  ClusterView.newCluster(this._key, int id) {
    if (this._cluster == null) {
      _cluster = Cluster(id: id);
      _new = true;
    }
  }

  @override
  ClusterViewState createState() => ClusterViewState();
}
