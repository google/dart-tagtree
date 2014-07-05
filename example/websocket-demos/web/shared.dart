library shared;

import "package:tagtree/core.dart";

/**
 * Requests a button demo.
 */
class ButtonDemo extends JsonTag {
  const ButtonDemo();
  get maker => $maker;

  static const $maker = const TagMaker(
      jsonTag: "ButtonDemo",
      fromMap: fromMap,
      toProps: toProps
  );
  static fromMap(_) => new ButtonDemo();
  static toProps(_) => new PropsMap({});
}

/**
 * Requests that a file be tailed.
 */
class TailDemo extends JsonTag {
  const TailDemo();
  get maker => $maker;

  static const $maker = const TagMaker(
      jsonTag: "TailDemo",
      fromMap: fromMap,
      toProps: toProps
  );
  static fromMap(_) => new TailDemo();
  static toProps(_) => new PropsMap({});
}

/**
 * A file snapshot returned by [TailDemo].
 */
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
  get maker => $maker;

  static const $maker = const TagMaker(
    jsonTag: "TailSnapshot",
    fromMap: fromMap,
    toProps: toProps
  );
  static fromMap(m) => new TailSnapshot._fromMap(m);
  static toProps(TailSnapshot tag) => new PropsMap({"lines": tag.lines});
}
