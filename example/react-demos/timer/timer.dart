import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class SecondsElapsed extends View {
  const SecondsElapsed();
}

class _SecondsElapsed extends Widget<SecondsElapsed, int> {
  _SecondsElapsed() {
    var timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());
    willUnmount.listen((_) => timer.cancel());
  }

  @override
  createFirstState() => 0;

  tick() {
    nextState = state + 1;
  }

  @override
  render() => $.Div(inner: "Seconds elapsed: ${state}");
}

main() =>
    getRoot("#container")
      ..theme.defineWidget(SecondsElapsed, () => new _SecondsElapsed())
      ..mount(const SecondsElapsed());
