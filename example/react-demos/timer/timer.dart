import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TimerApp extends View {
  const TimerApp();

  @override
  createExpander() => new _TimerApp();
}

class _TimerApp extends Widget<TimerApp, int> {
  var timer;

  @override
  getFirstState(_) {
    var timer = new Timer.periodic(new Duration(seconds: 1), tick);
    addTearDown(() => timer.cancel());
    return 0;
  }

  tick(_) {
    nextState = state + 1;
  }

  @override
  render() => $.Div(inner: "Seconds elapsed: ${state}");
}

main() => getRoot("#container").mount(const TimerApp());
