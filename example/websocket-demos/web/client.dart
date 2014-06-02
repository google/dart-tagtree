import "package:tagtree/browser.dart";

import "shared.dart";

final $ = new HtmlTagSet()
  ..defineTag("TextFile", (m) => new TextFile.fromMap(m));

main() =>
    root("#view", $)
        ..addTemplate("TextFile", renderTextFile)
        ..addWidget("Slot", () => new SlotWidget())
        ..mount(new Slot(src: "ws://localhost:8080/ws", tagSet: $));

renderTextFile(TextFile view) =>
    $.Pre(inner: view.lines.join("\n"));
