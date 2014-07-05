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
  get maker => $TextFile;

  static fromMap(Map<String, dynamic> m) => new TextFile._fromMap(m);
  static toProps(TextFile tag) => new PropsMap({"lines": tag.lines});
}

const $TextFile = const TagMaker(
  jsonTag: "TextFile",
  fromMap: TextFile.fromMap,
  toProps: TextFile.toProps
);
