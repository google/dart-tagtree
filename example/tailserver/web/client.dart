import "dart:html";

import "package:viewtree/browser.dart";

main() {
  mountWebSocket("ws://${window.location.hostname}:${window.location.port}/ws", "#view");
}
