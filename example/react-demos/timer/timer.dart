import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TimerApp extends AnimatedTag<int> {
  const TimerApp();

  @override
  start() {
    var p = new Place(0);

    var tick = (_) {
      p.nextState += 1;
    };

    Timer timer = new Timer.periodic(new Duration(seconds: 1), tick);
    p.onCut = (_) {
      timer.cancel();
    };

    return p;
  }

  @override
  renderAt(Place<int> p) => $.Div(inner: "Seconds elapsed: ${p.state}");
}

main() =>
    getRoot("#container")
      .mount(const TimerApp());
