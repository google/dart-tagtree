import "package:tagtree/browser.dart";
import "package:tagtree/core.dart";

import "shared.dart";

class _TextFile extends Template {
  const _TextFile();

  @override
  render(TextFile props) => $.Pre(inner: props.lines.join("\n"));
}

final exportedTags = new HtmlTagSet()
  ..export(TextFile.tag, TextFile.fromMap);

final theme = new Theme(const {
  TextFile: const _TextFile(),
  Slot: SlotWidget.create,
});

main() =>
    getRoot("#view")
        ..mount(new Slot(src: "ws://localhost:8080/ws", export: exportedTags), theme);
