import 'package:flutter/material.dart';
import 'package:clusterup/log.dart';

class LogViewState extends State<LogView> {
  LogViewState();
  String log = "";
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    log = Log.get();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    });

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text("View Log"),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              log,
              style: TextStyle(color: Colors.amberAccent, fontFamily: "monospace"),
            ),
          ),
        ));
  }
}

class LogView extends StatefulWidget {
  @override
  LogViewState createState() => LogViewState();
}
