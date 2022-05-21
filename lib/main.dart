import 'package:flutter/material.dart';
import 'views/clusters_view.dart';
import 'package:clusterup/log.dart';

void main() {
  log("Starting");
  runApp(MyApp());
}

// https://flutter.dev/docs/get-started/codelab
// https://codelabs.developers.google.com/codelabs/first-flutter-app-pt2/#0
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cluster Up',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xff282828),
        primaryColor: Color(0xff575757),
      ),
      home: ClustersView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
