import "package:tagtree/browser.dart";

import "shared.dart";

renderTextFile(TextFile view) =>
    $.Pre(inner: view.lines.join("\n"));

final exportedTags = new HtmlTagSet()
  ..export("TextFile", (m) => new TextFile.fromMap(m));

main() =>
    getRoot("#view")
        ..theme.defineTemplate(TextFile, renderTextFile)
        ..theme.defineWidget(Slot, () => new SlotWidget())
        ..mount(new Slot(src: "ws://localhost:8080/ws", export: exportedTags));
