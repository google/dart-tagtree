library shared;

import "package:tagtree/core.dart";

class TextFile extends TaggedNode {
  String get tag => "TextFile";
  final List<String> lines;
  const TextFile({this.lines});
  TextFile.fromMap(Map<String, dynamic> m) : this(lines: m["lines"]);
  get propsMap => {"lines": lines};
}
