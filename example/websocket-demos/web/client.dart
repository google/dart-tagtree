import "package:viewtree/browser.dart";
import "package:viewtree/core.dart";

import "shared.dart";

final $ = new TagSet()
  ..defineTemplate(
      type: TextFileType,
      render: ({List<String> lines}) => $.Pre(inner: lines.join("\n"))
  );

main() {
  mountWebSocket("ws://localhost:8080/ws", "#view", $);
}
