import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

class SecondsElapsed extends View {
  const SecondsElapsed();
}

main() =>
    root("#container")
      ..theme = theme
      ..mount(const SecondsElapsed());

final theme = new Theme($)
    ..defineWidget(SecondsElapsed, () => new _SecondsElapsed());

class _SecondsElapsed extends Widget<SecondsElapsed, int> {
  Timer timer;

  _SecondsElapsed() {
    timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());
    willUnmount.listen((_) => timer.cancel());
  }

  @override
  setProps(_) {}

  @override
  int createFirstState() => 0;

  int get seconds => state;

  tick() {
    nextState = seconds + 1;
  }

  @override
  View render() => $.Div(inner: "Seconds elapsed: ${seconds}");
}
