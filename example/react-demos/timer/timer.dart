import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TimerApp extends AnimatedView<int> {
  const TimerApp();

  @override
  makePlace() => new Ticker(firstState);

  @override
  get firstState => 0;

  @override
  renderFrame(Place p) => $.Div(inner: "Seconds elapsed: ${p.state}");
}

class Ticker extends Place {
  Timer timer;
  Ticker(int firstTick) : super(firstTick) {
    timer = new Timer.periodic(new Duration(seconds: 1), tick);
  }

  tick(_) {
    nextState += 1;
  }

  @override
  unmount() {
    timer.cancel();
    timer = null;
    super.unmount();
  }
}

main() =>
    getRoot("#container")
      .mount(const TimerApp());
