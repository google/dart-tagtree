library shared;

import "package:tagtree/core.dart";

class TextFile extends View {
  @override
  get jsonTag => "TextFile";

  final List<String> lines;
  const TextFile({this.lines});

  TextFile.fromMap(Map<String, dynamic> m) :
    this(lines: m["lines"]);

  @override
  checked() {
    assert(lines != null);
    return true;
  }

  @override
  get propsImpl => {"lines": lines};
}
