import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

class SecondsElapsed extends TaggedNode {
  get tag => "SecondsElapsed";
  const SecondsElapsed();
}

main() =>
    root("#container")
      ..addWidget("SecondsElapsed", () => new _SecondsElapsed())
      ..mount(const SecondsElapsed());

class _SecondsElapsed extends Widget<SecondsElapsed, int> {
  Timer timer;

  _SecondsElapsed() {
    timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());

    willUnmount.listen((_) => timer.cancel());
  }

  setProps(_) {}

  @override
  int createFirstState() => 0;

  int get seconds => state;

  tick() {
    nextState = seconds + 1;
  }

  ElementNode render() => $.Div(inner: "Seconds elapsed: ${seconds}");
}
