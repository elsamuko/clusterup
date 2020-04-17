// https://github.com/dart-lang/site-www/blob/master/examples/httpserver/bin/static_file_server.dart

import 'dart:io';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:mime/mime.dart';
import 'package:http_server/http_server.dart';

void serveForever(String folder) async {
  dev.log("Running server on http://localhost:3001");
  HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 3001);

  if (server == null) {
    dev.log("Could not start server");
    return;
  }

  VirtualDirectory staticFiles = VirtualDirectory(folder);
  staticFiles.allowDirectoryListing = true;
  staticFiles.directoryHandler = (dir, request) {
    Uri indexUri = Uri.file(dir.path).resolve('index.html');
    staticFiles.serveFile(File(indexUri.toFilePath()), request);
  };

  await for (HttpRequest request in server) {
    if (request.uri.path.startsWith("/stop")) break;

    if (request.method == "POST" && request.uri.path.startsWith("/upload")) {
      // String content = await utf8.decoder.bind(request).join();
      String boundary = request.headers.contentType.parameters['boundary'];
      MimeMultipart part = await MimeMultipartTransformer(boundary).bind(request).first;
      String json = await utf8.decoder.bind(part).join();
      File jsonFile = File("$folder/clusterup.json");
      jsonFile.writeAsStringSync(json);
      request.response.redirect(Uri.parse('/'));
      request.response.close();
    }

    if (request.method == "GET") {
      staticFiles.serveRequest(request);
    }
  }

  server.close();
  dev.log("Server stopped");
}

class Http {
  static Future<String> GET(String url) async {
    HttpClientRequest request = await HttpClient().getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    return utf8.decoder.bind(response).first;
  }
}

class Server {
  void start(String folder) {
    serveForever(folder);
  }

  void stop() async {
    dev.log("Send stop request");
    await Http.GET('http://localhost:3001/stop');
  }
}
