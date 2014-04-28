import "package:viewtree/browser.dart";
import "package:viewtree/core.dart";

final $ = new TagMaker();

main() {
  mountWebSocket("ws://localhost:8080/ws", "#view", $);
}
