library shared;

import "package:tagtree/core.dart";

class TextFile extends Tag {
  final List<String> lines;

  const TextFile({this.lines});

  TextFile._fromMap(Map<String, dynamic> props) :
    this(lines: props["lines"]);

  @override
  checked() {
    assert(lines != null);
    return true;
  }

  @override
  get animator => null; // theme must provide

  @override
  get propsImpl => {"lines": lines};

  @override
  get jsonTag => $TextFile.jsonTag;

  static fromMap(Map<String, dynamic> m) => new TextFile._fromMap(m);
}

const $TextFile = const TagMaker(
  jsonTag: "TextFile",
  fromMap: TextFile.fromMap
);
