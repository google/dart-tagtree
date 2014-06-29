import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TimerApp extends View {
  const TimerApp();

  @override
  get animator => const _TimerApp();
}

class _TimerApp extends Animator<TimerApp, int> {
  const _TimerApp();

  @override
  makePlace(PlaceImpl impl, TimerApp app) => new TickerPlace(firstState(app));

  @override
  firstState(_) => 0;

  @override
  renderFrame(Place p) => $.Div(inner: "Seconds elapsed: ${p.state}");

  @override
  onEnd(TickerPlace place) => place.stop();
}

class TickerPlace extends Place<dynamic, int> {
  Timer timer;
  TickerPlace(int firstState) : super(firstState) {
    timer = new Timer.periodic(new Duration(seconds: 1), tick);
  }

  tick(_) => step((seconds) => seconds + 1);

  stop() {
    timer.cancel();
    timer = null;
  }
}

main() =>
    getRoot("#container")
      .mount(const TimerApp());
