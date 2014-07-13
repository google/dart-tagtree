// A websocket server that makes two demos available.
/// To use: run this command and then run web/client.html in Dartium.

import "dart:io";

import "demos/button.dart" as button;
import "demos/tail.dart" as tail;
import "../pixelpaint/pixelpaint.dart" as pixelpaint;

import "web/shared.dart";

import "package:tagtree/core.dart";
import "package:tagtree/server.dart";

const exports = const [
    ButtonDemoRequest.$jsonType,
    TailDemoRequest.$jsonType,
    TailSnapshot.$jsonType,
    pixelpaint.PixelPaintApp.$jsonType,
    pixelpaint.GridView.$jsonType,
    pixelpaint.Grid.$jsonType
];
final $ = new HtmlTagSet.withTags(exports);

main(List<String> args) {

  // watch this file
  var watcher = new tail.TailWatcher(new File(Platform.script.toFilePath()), 50);

  Animator getAnimator(Jsonable request) {
    if (request is ButtonDemoRequest) {
      return const button.ButtonAnimator();
    } else if (request is TailDemoRequest) {
      return new tail.TailAnimator(watcher);
    } else if (request is pixelpaint.PixelPaintApp) {
      return const pixelpaint.PixelPaintAnimator();
    }
    return null;
  }

  HttpServer.bind("localhost", 8081).then((server) {

    print("\nThe demo server is ready.");
    print("Please run web/demo-client.html in Dartium\n");
    server.listen((request) {
      String path = request.uri.path;
      if (path == "/ws") {
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          print("websocket connected");
          socketRoot(socket, $, getAnimator).start();
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

