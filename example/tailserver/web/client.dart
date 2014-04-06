import "package:viewtree/browser.dart";

main() {
  mountWebSocket("ws://localhost:8080/ws", "#view");
}
