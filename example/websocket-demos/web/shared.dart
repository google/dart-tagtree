library shared;

import "package:tagtree/core.dart";

/// A server-side demo demonstrating event handling.
class ButtonDemo extends JsonTag {
  const ButtonDemo();

  @override
  get jsonType => $jsonType;
  static const $jsonType = const JsonType("ButtonDemo", toMap, fromMap);
  static toMap(ButtonDemo _) => const {};
  static fromMap(Map _) => const ButtonDemo();
}

/// A server-side demo demonstrating view updating.
class TailDemo extends JsonTag {
  final int lineCount;
  const TailDemo(this.lineCount);

  @override
  get jsonType => $jsonType;
  static const $jsonType = const JsonType("TailDemo", toMap, fromMap);
  static toMap(TailDemo tag) => {"lineCount": tag.lineCount};
  static fromMap(Map props) => new TailDemo(props["lineCount"]);
}

/// A file snapshot returned by [TailDemo].
class TailSnapshot extends JsonTag {
  final List<String> lines;
  const TailSnapshot({this.lines});

  @override
  get jsonType => $jsonType;
  static const $jsonType = const JsonType("TailSnapshot", toMap, fromMap);
  static toMap(TailSnapshot tag) => {"lines": tag.lines};
  static fromMap(m) => new TailSnapshot(lines: m["lines"]);
}
