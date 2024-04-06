import 'package:clusterup/ssh_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clusterup/log.dart';
import '../cluster.dart';
import '../ssh_connection.dart';
import '../cluster_child.dart';

class ClusterChildViewState extends State<ClusterChildView> {
  ClusterChildViewState();

  final _formKey = GlobalKey<FormState>();
  bool testingConnection = false;

  void validate() {
    var current = _formKey.currentState;
    if (current != null && current.validate()) {
      current.save();
    }
  }

  void _testSSH() async {
    log("Testing ${widget._child}");
    setState(() {
      testingConnection = true;
    });

    if (widget._key != null) {
      SSHConnectionResult result = await SSHConnection.test(widget._child.creds(), widget._key!);
      String text = result.success ? "SSH connection successful!" : "SSH connection failed : ${result.error}";
      final snackBar = SnackBar(content: Text(text));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    setState(() {
      testingConnection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = "Edit child";
    List<Widget> checkButton = [];

    if (widget._new) {
      title = "Add new child";
      checkButton.add(IconButton(
        icon: Icon(Icons.check_circle, size: 35, color: Colors.white),
        key: Key("saveChild"),
        onPressed: () {
          var current = _formKey.currentState;
          if (current != null && current.validate()) {
            current.save();
            log("Saving new ClusterChild ${widget._child}");
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
          var current = _formKey.currentState;
          if (!widget._new && current != null && current.validate()) {
            current.save();
            Navigator.pop(context, widget._child);
            return false;
          } else {
            log("Abort new child");
            return true;
          }
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: checkButton,
            ),
            bottomNavigationBar: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
              TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    var current = _formKey.currentState;
                    if (current != null && current.validate() && !testingConnection) {
                      current.save();
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
                                    key: Key("username"),
                                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
                                    onSaved: (String? value) {
                                      if (value?.isNotEmpty ?? false) {
                                        widget._child.user = value;
                                      }
                                    },
                                    initialValue: widget._child.user,
                                    validator: (String? value) {
                                      return (value ?? "").contains('@') ? 'Do not use the @ char.' : null;
                                    },
                                    onEditingComplete: validate,
                                  ),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      icon: Icon(Icons.computer),
                                      hintText: widget._child.parent.host,
                                      labelText: 'server',
                                    ),
                                    key: Key("server"),
                                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
                                    onSaved: (String? value) {
                                      if (value?.isNotEmpty ?? false) {
                                        widget._child.host = value;
                                      }
                                    },
                                    initialValue: widget._child.host,
                                    validator: (String? value) {
                                      return (value ?? "").contains('@') ? 'Do not use the @ char.' : null;
                                    },
                                    onEditingComplete: validate,
                                  ),
                                  TextFormField(
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.password),
                                      hintText: 'Password',
                                      labelText: 'password',
                                    ),
                                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp("[ ]"))],
                                    key: Key("password"),
                                    onSaved: (String? value) {
                                      if (value?.isNotEmpty ?? false) {
                                        widget._child.password = value;
                                      }
                                    },
                                    initialValue: widget._child.password,
                                    validator: (String? value) {
                                      return null;
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
                                    key: Key("port"),
                                    onSaved: (String? value) {
                                      widget._child.port = int.tryParse(value ?? "22");
                                    },
                                    initialValue: widget._child.port?.toString() ?? "",
                                    validator: (String? value) {
                                      if ((value ?? "").isEmpty) return null;
                                      int? port = int.tryParse(value!);
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
  SSHKey? _key;
  bool _new = false;

  ClusterChildView(this._key, this._child);

  ClusterChildView.newClusterChild(this._key, Cluster cluster)
      : _child = ClusterChild(cluster),
        _new = true;

  @override
  ClusterChildViewState createState() => ClusterChildViewState();
}
