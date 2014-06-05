import "package:tagtree/browser.dart";

import "shared.dart";

final $ = new HtmlTagSet()
  ..defineTag("TextFile", (m) => new TextFile.fromMap(m));

main() =>
    root("#view")
        ..theme = theme
        ..mount(new Slot(src: "ws://localhost:8080/ws", export: $));

final theme = new Theme()
  ..defineElements($)
  ..defineTemplate("TextFile", renderTextFile)
  ..defineWidget(Slot, () => new SlotWidget());

renderTextFile(TextFile view) =>
    $.Pre(inner: view.lines.join("\n"));
