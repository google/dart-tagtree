library shared;

import "package:tagtree/core.dart";

/// A server-side demo demonstrating event handling.
class ButtonDemo extends JsonTag {
  const ButtonDemo();
  get jsonType => $maker;

  static const $maker = const TagMaker(
      jsonTag: "ButtonDemo",
      fromMap: fromMap,
      toProps: toProps
  );
  static fromMap(_, _2) => new ButtonDemo();
  static toProps(_) => new PropsMap({});
}

/// A server-side demo demonstrating view updating.
class TailDemo extends JsonTag {
  final int lineCount;
  const TailDemo(this.lineCount);
  get jsonType => $maker;

  static const $maker = const TagMaker(
      jsonTag: "TailDemo",
      fromMap: fromMap,
      toProps: toProps
  );
  static fromMap(Map props, _) => new TailDemo(props["lineCount"]);
  static toProps(TailDemo tag) => new PropsMap({"lineCount": tag.lineCount});
}

/// A file snapshot returned by [TailDemo].
class TailSnapshot extends JsonTag {
  final List<String> lines;

  const TailSnapshot({this.lines});

  TailSnapshot._fromMap(Map<String, dynamic> props) :
    this(lines: props["lines"]);

  @override
  checked() {
    assert(lines != null);
    return true;
  }

  @override
  get animator => null; // theme must provide

  @override
  get jsonType => $maker;

  static const $maker = const TagMaker(
    jsonTag: "TailSnapshot",
    fromMap: fromMap,
    toProps: toProps
  );
  static fromMap(m,_) => new TailSnapshot._fromMap(m);
  static toProps(TailSnapshot tag) => new PropsMap({"lines": tag.lines});
}
