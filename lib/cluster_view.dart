import 'package:clusterup/remote_action_results_view.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'remote_actions_view.dart';
import 'ssh_connection.dart';
import 'cluster.dart';
import 'remote_action.dart';

class ClusterViewState extends State<ClusterView> {
  ClusterViewState();

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool testingConnection = false;

  void validate() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
    }
  }

  void _testSSH() async {
    dev.log("Testing ${widget._cluster}");
    setState(() {
      testingConnection = true;
    });

    SSHConnectionResult result = await SSHConnection.test(widget._cluster, widget._key);

    String text = result.success ? "SSH connection successful!" : "SSH connection failed : ${result.error}";
    final snackBar = SnackBar(content: Text(text));
    _scaffoldKey.currentState.showSnackBar(snackBar);

    setState(() {
      testingConnection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    dev.log("NewClusterState");
    String title = "Edit cluster";
    List<Widget> checkButton = [];

    if (widget._new) {
      title = "Add new cluster";
      checkButton.add(IconButton(
        icon: Icon(Icons.check_circle, size: 35, color: Color(0xff50da47)),
        onPressed: () {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
            dev.log("Saving new cluster ${widget._cluster}");
            Navigator.pop(context, widget._cluster);
          }
        },
      ));
    }

    var indicator = testingConnection
        ? SizedBox(
            child: CircularProgressIndicator(),
            height: 15.0,
            width: 15.0,
          )
        : Text(
            "Test connection",
          );

    return WillPopScope(
        onWillPop: () async {
          if (!widget._new && _formKey.currentState.validate()) {
            _formKey.currentState.save();
            Navigator.pop(context, widget._cluster);
            return false;
          } else {
            dev.log("Abort new cluster");
            return true;
          }
        },
        child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(title),
              actions: checkButton,
            ),
            body: ListView(children: <Widget>[
              Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Card(
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
                                    inputFormatters: [BlacklistingTextInputFormatter(RegExp("[ ]"))],
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
                                    inputFormatters: [BlacklistingTextInputFormatter(RegExp("[ ]"))],
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
                              ))))),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: FlatButton(
                      color: Colors.blue[800],
                      textColor: Colors.white,
                      onPressed: () async {
                        if (_formKey.currentState.validate() && !testingConnection) {
                          _formKey.currentState.save();
                          _testSSH();
                        }
                      },
                      child: indicator)),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: FlatButton(
                      color: Colors.orange[900],
                      textColor: Colors.white,
                      onPressed: () async {
                        dev.log("Configure Actions");
                        Set<RemoteAction> selected = await Navigator.of(context).push(
                          MaterialPageRoute<Set<RemoteAction>>(
                            builder: (BuildContext context) {
                              return ActionsView(saved: widget._cluster.actions);
                            },
                          ),
                        );

                        widget._cluster.actions = selected;
                      },
                      child: Text(
                        "Actions",
                      ))),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: FlatButton(
                      color: Colors.green[600],
                      textColor: Colors.white,
                      onPressed: () async {
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) {
                          return ResultsView(widget._key, widget._cluster, true);
                        }));
                      },
                      child: Text(
                        "Run",
                      ))),
            ])));
  }
}

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
