import "package:tagtree/browser.dart";
import "package:tagtree/core.dart";

import "shared.dart";

final textFileTemplate = new Template((TextFile props) =>
    $.Pre(inner: props.lines.join("\n"))
);

final exportedTags = new HtmlTagSet()
  ..export("TextFile", (m) => new TextFile.fromMap(m));

final theme = new Theme($)
    ..define(TextFile, () => textFileTemplate)
    ..define(Slot, () => new SlotWidget());

main() =>
    getRoot("#view")
        ..mount(new Slot(src: "ws://localhost:8080/ws", export: exportedTags), theme);
