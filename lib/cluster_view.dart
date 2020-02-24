import 'package:clusterup/ssh_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'ssh_connection.dart';
import 'cluster.dart';

class ClusterViewState extends State<ClusterView> {
  ClusterViewState();

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    dev.log("NewClusterState");
    String title =
        (widget._cluster != null) ? 'Edit cluster' : 'Add new cluster';

    void _testSSH() async {
      dev.log("Testing ${widget._cluster}");
      SSHConnectionResult result = await SSHConnection.test(
          widget._cluster.user,
          widget._cluster.host,
          widget._cluster.port,
          widget._key);

      String text = result.success
          ? "SSH connection successful!"
          : "SSH connection failed : ${result.error}";
      final snackBar = SnackBar(content: Text(text));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check, size: 30),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  dev.log("Saving new cluster ${widget._cluster}");
                  Navigator.pop(context, widget._cluster);
                }
              },
            ),
          ],
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
                                inputFormatters: [
                                  BlacklistingTextInputFormatter(RegExp("[ ]"))
                                ],
                                onSaved: (String value) {
                                  widget._cluster.user = value;
                                },
                                initialValue: widget._cluster?.user,
                                validator: (String value) {
                                  return value.contains('@')
                                      ? 'Do not use the @ char.'
                                      : null;
                                },
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.computer),
                                  hintText: 'Server domain',
                                  labelText: 'server',
                                ),
                                inputFormatters: [
                                  BlacklistingTextInputFormatter(RegExp("[ ]"))
                                ],
                                onSaved: (String value) {
                                  widget._cluster.host = value;
                                },
                                initialValue: widget._cluster?.host,
                                validator: (String value) {
                                  return value.contains('@')
                                      ? 'Do not use the @ char.'
                                      : null;
                                },
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
                                initialValue:
                                    (widget._cluster?.port ?? 22).toString(),
                                validator: (String value) {
                                  if (int.tryParse(value) == 0) {
                                    return "Invalid port number";
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                            ],
                          ))))),
          Container(
              margin: const EdgeInsets.all(20.0),
              child: FlatButton(
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      _testSSH();
                    }
                  },
                  child: Text(
                    "Test connection",
                  ))),
        ]));
  }
}

class ClusterView extends StatefulWidget {
  Cluster _cluster;
  SSHKey _key;

  ClusterView(this._key, this._cluster);

  ClusterView.newCluster(this._key, int id) {
    if (this._cluster == null) {
      _cluster = Cluster(id);
    }
  }

  @override
  ClusterViewState createState() => ClusterViewState();
}
