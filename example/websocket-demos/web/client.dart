import "package:viewtree/browser.dart";
import "package:viewtree/core.dart";

final $ = new TagSet()
  ..defineTemplate(
      method: #textFile,
      jsonName: "textFile",
      props: [new PropType(#lines, "lines")],
      render: ({List<String> lines}) => $.Pre(inner: lines.join("\n"))
  );

main() {
  mountWebSocket("ws://localhost:8080/ws", "#view", $);
}
