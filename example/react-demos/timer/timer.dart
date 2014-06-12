import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TimerApp extends View {
  const TimerApp();

  @override
  createViewer() => new _TimerApp();
}

class _TimerApp extends Widget<TimerApp, int> {
  _TimerApp() {
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

main() => getRoot("#container").mount(const TimerApp());
