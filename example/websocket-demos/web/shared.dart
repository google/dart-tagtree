library shared;

import "package:tagtree/core.dart";

class TextFile extends View {
  @override
  get jsonTag => tag;

  final List<String> lines;
  const TextFile({this.lines});

  TextFile._fromMap(Map<String, dynamic> m) :
    this(lines: m["lines"]);

  @override
  checked() {
    assert(lines != null);
    return true;
  }

  @override
  get animator => null; // theme must provide

  @override
  get propsImpl => {"lines": lines};

  static final tag = "TextFile";
  static fromMap(Map<String, dynamic> m) => new TextFile._fromMap(m);
}
