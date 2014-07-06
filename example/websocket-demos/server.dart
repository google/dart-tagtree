// A websocket server that makes two demos available.
/// To use: run this command and then run web/client.html in Dartium.

import "dart:io";

import "demos/button.dart" as button;
import "demos/tail.dart" as tail;

import "web/shared.dart";

import "package:tagtree/core.dart";
import "package:tagtree/server.dart";

final $ = new HtmlTagSet.withTags([ButtonDemo.$maker, TailDemo.$maker, TailSnapshot.$maker]);

main(List<String> args) {

  // watch this file
  var watcher = new tail.TailWatcher(new File(Platform.script.toFilePath()), 50);

  makeSession(Tag request) {
    if (request is ButtonDemo) {
      return new button.ButtonDemoSession();
    } else if (request is TailDemo) {
      return new tail.TailDemoSession(watcher);
    }
    return null;
  }

  HttpServer.bind("localhost", 8081).then((server) {

    print("\nThe server is ready.");
    print("Please run web/client.html in Dartium\n");
    server.listen((request) {
      String path = request.uri.path;
      if (path == "/ws") {
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          print("websocket connected");
          socketRoot(socket, $, makeSession).start();
        });
      } else {
        sendNotFound(request);
      }
    });
  });
}

sendNotFound(HttpRequest request) {
  print("sending not found for ${request.uri.path}");
  request.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..write('Not found')
      ..close();
}
