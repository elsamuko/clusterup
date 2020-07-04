// https://github.com/dart-lang/site-www/blob/master/examples/httpserver/bin/static_file_server.dart

import 'dart:io';
import 'dart:convert';
import 'package:clusterup/log.dart';
import 'package:mime/mime.dart';
import 'package:http_server/http_server.dart';

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
  void Function(String) onJsonOrKey;
  HttpServer server;

  Server(this.socket);

  bool isRunning() {
    return server != null;
  }

  void serveForever(String folder) async {
    log("Running server on http://localhost:$socket, to access emulator, run");
    log("adb forward tcp:$socket tcp:$socket");

    this.server = await HttpServer.bind(InternetAddress.anyIPv4, socket);

    if (this.server == null) {
      log("Could not start server");
      return;
    }

    VirtualDirectory staticFiles = VirtualDirectory(folder);
    staticFiles.allowDirectoryListing = true;
    staticFiles.directoryHandler = (dir, request) {
      Uri indexUri = Uri.file(dir.path).resolve('index.html');
      staticFiles.serveFile(File(indexUri.toFilePath()), request);
    };

    await for (HttpRequest request in this.server) {
      if (request.uri.path == "/clusterup.json") {
        request.response.write(this.json);
        request.response.close();
        continue;
      }

      if (request.method == "POST" && request.uri.path.startsWith("/upload")) {
        // parse multipart request
        String boundary = request.headers.contentType.parameters['boundary'];
        MimeMultipart part = await MimeMultipartTransformer(boundary).bind(request).first;
        String json = await utf8.decoder.bind(part).join();
        if (this.onJsonOrKey != null) {
          this.onJsonOrKey(json);
        }

        request.response.redirect(Uri.parse('/'));
        request.response.close();
        continue;
      }

      if (request.method == "GET") {
        staticFiles.serveRequest(request);
      }
    }

    log("Server stopped");
  }

  void start(String folder) {
    serveForever(folder);
  }

  void stop() async {
    if (this.server != null) {
      log("Stopping server");
      await this.server.close(force: true);
      this.server = null;
    }
  }
}
