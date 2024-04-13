// https://pub.dev/packages/shelf/example

import 'dart:io';
import 'dart:convert';
import 'package:clusterup/log.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class Http {
  static Future<String> GET(String url) async {
    HttpClientRequest request = await HttpClient().getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    return utf8.decoder.bind(response).first;
  }
}

class Server {
  int socket;
  String json = "";
  Function? onJsonOrKey;
  HttpServer? server;

  Server(this.socket);

  bool isRunning() {
    return server != null;
  }

  Future<Response> requestHandler(Request request) async {
    if (request.url.path == "clusterup.json") {
      return Response.ok(this.json);
    }

    if (request.method == "POST" && request.url.path == "upload") {
      log("Requested upload");
      // parse multipart request
      String? contentType = request.headers["content-type"];
      if (contentType == null) {
        log("No content-type in upload request");
        return Response.movedPermanently("/");
      }
      int pos = contentType.indexOf("boundary=");
      if (pos == -1) {
        log("No boundary in content-type");
        return Response.movedPermanently("/");
      }

      String boundary = contentType.substring(pos + 9);
      MimeMultipart part = await MimeMultipartTransformer(boundary).bind(request.read()).first;
      String json = await utf8.decoder.bind(part).join();
      if (this.onJsonOrKey != null) {
        log("Received json");
        this.onJsonOrKey!(json);
      }

      return Response.movedPermanently("/");
    }

    return Response.ok("");
  }

  void serveForever(String folder) async {
    log("Running server on http://localhost:$socket, to access emulator, run");
    log("adb forward tcp:$socket tcp:$socket");

    var staticHandler = createStaticHandler(folder, defaultDocument: 'index.html');
    var dynHandler = const Pipeline().addMiddleware(logRequests()).addHandler(requestHandler);
    var handler = new Cascade().add(staticHandler).add(dynHandler).handler;
    this.server = await shelf_io.serve(handler, InternetAddress.anyIPv4, socket);

    if (this.server == null) {
      log("Could not start server");
      return;
    }
  }

  void start(String folder) {
    serveForever(folder);
  }

  void stop() async {
    if (this.server != null) {
      log("Stopping server");
      await this.server!.close(force: true);
      this.server = null;
    }
  }
}
