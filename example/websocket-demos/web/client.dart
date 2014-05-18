import "package:viewtree/browser.dart";
import "package:viewtree/core.dart";

final $ = new TagMaker()
  ..defineTemplate(
      method: #textFile,
      jsonName: "textFile",
      props: [new PropDef(#lines, "lines")],
      render: ({List<String> lines}) => $.Pre(inner: lines.join("\n"))
  );

main() {
  mountWebSocket("ws://localhost:8080/ws", "#view", $);
}
