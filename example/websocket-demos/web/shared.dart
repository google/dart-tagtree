library shared;

import "package:tagtree/core.dart";

/**
 * Requests a button demo.
 */
class ButtonDemo extends JsonTag {
  const ButtonDemo();
  get maker => $ButtonDemo;

  static fromMap(_) => new ButtonDemo();
  static toProps(_) => new PropsMap({});
}

const $ButtonDemo = const TagMaker(
    jsonTag: "ButtonDemo",
    fromMap: ButtonDemo.fromMap,
    toProps: ButtonDemo.toProps
);

/**
 * Requests that a file be tailed.
 */
class TailDemo extends JsonTag {
  const TailDemo();
  get maker => $TailDemo;

  static fromMap(_) => new TailDemo();
  static toProps(_) => new PropsMap({});
}

const $TailDemo = const TagMaker(
    jsonTag: "TailDemo",
    fromMap: TailDemo.fromMap,
    toProps: TailDemo.toProps
);

/**
 * An animation frame returned by [TailDemo].
 */
class TextFile extends JsonTag {
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
