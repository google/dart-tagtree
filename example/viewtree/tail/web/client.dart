import "dart:html";

import "package:viewtree/core.dart";
import "package:viewtree/browser.dart";

main() {
  var ws = new WebSocket("ws://${window.location.hostname}:${window.location.port}/ws");
  ws.onMessage.listen((MessageEvent e) {
    print("rendering view from socket");
    View view = Elt.rules.decodeTree(e.data);
    mount(view, "#view");
  });
}
