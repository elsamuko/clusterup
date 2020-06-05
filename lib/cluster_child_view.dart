import 'package:clusterup/ssh_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'cluster.dart';
import 'ssh_connection.dart';
import 'cluster_child.dart';

class ClusterChildViewState extends State<ClusterChildView> {
  ClusterChildViewState();

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool testingConnection = false;

  void validate() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
    }
  }

  void _testSSH() async {
    dev.log("Testing ${widget._child}");
    setState(() {
      testingConnection = true;
    });

    SSHConnectionResult result = await SSHConnection.test(widget._child.creds(), widget._key);

    String text = result.success ? "SSH connection successful!" : "SSH connection failed : ${result.error}";
    final snackBar = SnackBar(content: Text(text));
    _scaffoldKey.currentState.showSnackBar(snackBar);

    setState(() {
      testingConnection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    dev.log("NewClusterChildState");
    String title = "Edit child";
    List<Widget> checkButton = [];

    if (widget._new) {
      title = "Add new child";
      checkButton.add(IconButton(
        icon: Icon(Icons.check_circle, size: 35, color: Color(0xff50da47)),
        onPressed: () {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
            dev.log("Saving new ClusterChild ${widget._child}");
            Navigator.pop(context, widget._child);
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
            "Test",
          );

    return WillPopScope(
        onWillPop: () async {
          if (!widget._new && _formKey.currentState.validate()) {
            _formKey.currentState.save();
            Navigator.pop(context, widget._child);
            return false;
          } else {
            dev.log("Abort new child");
            return true;
          }
        },
        child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(title),
              actions: checkButton,
            ),
            bottomNavigationBar: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
              FlatButton(
                  color: Colors.blue[800],
                  textColor: Colors.white,
                  onPressed: () async {
                    if (_formKey.currentState.validate() && !testingConnection) {
                      _formKey.currentState.save();
                      _testSSH();
                    }
                  },
                  child: indicator),
            ]),
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
                                    decoration: InputDecoration(
                                      icon: Icon(Icons.person),
                                      hintText: widget._child.parent.user,
                                      labelText: 'username',
                                    ),
                                    inputFormatters: [BlacklistingTextInputFormatter(RegExp("[ ]"))],
                                    onSaved: (String value) {
                                      if (value.isNotEmpty) {
                                        widget._child.user = value;
                                      }
                                    },
                                    initialValue: widget._child?.user,
                                    validator: (String value) {
                                      return value.contains('@') ? 'Do not use the @ char.' : null;
                                    },
                                    onEditingComplete: validate,
                                  ),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      icon: Icon(Icons.computer),
                                      hintText: widget._child.parent.host,
                                      labelText: 'server',
                                    ),
                                    inputFormatters: [BlacklistingTextInputFormatter(RegExp("[ ]"))],
                                    onSaved: (String value) {
                                      if (value.isNotEmpty) {
                                        widget._child.host = value;
                                      }
                                    },
                                    initialValue: widget._child?.host,
                                    validator: (String value) {
                                      return value.contains('@') ? 'Do not use the @ char.' : null;
                                    },
                                    onEditingComplete: validate,
                                  ),
                                  TextFormField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      icon: Icon(Icons.local_airport),
                                      hintText: widget._child.parent.port.toString(),
                                      labelText: 'port',
                                    ),
                                    onSaved: (String value) {
                                      widget._child.port = int.tryParse(value);
                                    },
                                    initialValue: widget._child?.port ?? "",
                                    validator: (String value) {
                                      if (value.isEmpty) return null;
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
            ])));
  }
}

class ClusterChildView extends StatefulWidget {
  ClusterChild _child;
  SSHKey _key;
  bool _new = false;

  ClusterChildView(this._key, this._child);

  ClusterChildView.newClusterChild(this._key, Cluster cluster) {
    if (this._child == null) {
      _child = ClusterChild(cluster);
      _new = true;
    }
  }

  @override
  ClusterChildViewState createState() => ClusterChildViewState();
}
