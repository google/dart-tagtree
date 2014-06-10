import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TimerApp extends View {
  const TimerApp();
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

final tags = $.elements.extend({TimerApp: () => new _TimerApp()});
main() => getRoot("#container").mount(const TimerApp(), tags);
