import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TimerApp extends AnimatedTag<int> {
  const TimerApp();

  @override
  start() => new Ticker(new Duration(seconds: 1));

  @override
  renderAt(Ticker p) => $.Div(inner: "Seconds elapsed: ${p.state}");
}

class Ticker extends Place<int> {
  Timer timer;
  Ticker(Duration period) : super(0) {
    timer = new Timer.periodic(period, tick);
  }

  tick(_) {
    nextState += 1;
  }

  @override
  unmount() {
    timer.cancel();
    super.unmount();
  }
}

main() =>
    getRoot("#container")
      .mount(const TimerApp());
