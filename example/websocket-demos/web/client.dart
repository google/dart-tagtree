import "package:tagtree/browser.dart";

import "shared.dart";

final $ = new CustomTagSet()
  ..defineTemplate(
      type: TextFileType,
      render: ({List<String> lines}) => $.Pre(inner: lines.join("\n"))
  );

main() => root("#view").mount(Slot(src: "ws://localhost:8080/ws", tagSet: $));
