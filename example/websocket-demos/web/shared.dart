library shared;

import "package:tagtree/core.dart";

/// Requests a server-side demo demonstrating event handling.
class ButtonDemoRequest extends Jsonable {
  const ButtonDemoRequest();

  @override
  get jsonType => $jsonType;
  static const $jsonType = const JsonType("ButtonDemo", toMap, fromMap);
  static toMap(ButtonDemoRequest _) => const {};
  static fromMap(Map _) => const ButtonDemoRequest();
}

/// Requests a server-side demo demonstrating view updating.
class TailDemoRequest extends Jsonable {
  final int lineCount;
  const TailDemoRequest(this.lineCount);

  @override
  get jsonType => $jsonType;
  static const $jsonType = const JsonType("TailDemo", toMap, fromMap);
  static toMap(TailDemoRequest tag) => {"lineCount": tag.lineCount};
  static fromMap(Map props) => new TailDemoRequest(props["lineCount"]);
}

/// A file snapshot returned by [TailDemoRequest].
class TailSnapshot extends Tag implements Jsonable {
  final List<String> lines;
  const TailSnapshot({this.lines});

  @override
  get animator => null;

  @override
  get jsonType => $jsonType;
  static const $jsonType = const JsonType("TailSnapshot", toMap, fromMap);
  static toMap(TailSnapshot tag) => {"lines": tag.lines};
  static fromMap(m) => new TailSnapshot(lines: m["lines"]);
}
