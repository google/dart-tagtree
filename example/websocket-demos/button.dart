// A websocket server that prints a message whenever a button is pressed.
/// To use: run this command and then run web/client.html in Dartium.

import "dart:io";

import "package:viewtree/core.dart";
import "package:viewtree/server.dart";

main(List<String> args) {

  HttpServer.bind("localhost", 8080).then((server) {

    print("\nThe server is ready.");
    print("Please run web/client.html in Dartium\n");
    server.listen((request) {
      String path = request.uri.path;
      if (path == "/ws") {
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          print("websocket connected");
          socketRoot(socket).mount(new ButtonSession());
        });
      } else {
        sendNotFound(request);
      }
    });
  });
}

final $ = new HtmlTags();

class ButtonSession extends Session<int> {

  int createFirstState() => 0;

  int get clicks => state;

  onClick(_) {
    print("button clicked");
    nextState = clicks + 1;
  }

  Tag render() {
    return $.Div(inner: [
                 $.Div(inner: "Clicks: ${clicks}"),
                 $.Button(onClick: remote(onClick), inner: "Click to log a message"),
                ]);
  }
}

sendNotFound(HttpRequest request) {
  print("sending not found for ${request.uri.path}");
  request.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..write('Not found')
      ..close();
}