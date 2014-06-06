import "package:tagtree/browser.dart";
import "package:tagtree/core.dart";

import "shared.dart";

final textFileTemplate = new Template(TextFile,
    (TextFile props) => $.Pre(inner: props.lines.join("\n"))
);

final exportedTags = new HtmlTagSet()
  ..export("TextFile", (m) => new TextFile.fromMap(m));

main() =>
    getRoot("#view")
        ..theme.add(textFileTemplate)
        ..theme.define(Slot, () => new SlotWidget())
        ..mount(new Slot(src: "ws://localhost:8080/ws", export: exportedTags));
