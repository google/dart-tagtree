import 'dart:async' show Timer;
import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

void main() {
  root("#container").mount(SecondsElapsed());
}

final SecondsElapsed = defineWidget(
    props: () => true,
    state: (_) => new TimerState(0),
    widget: () => new TimerWidget()
);

final $ = new Tags();

class TimerState extends State {
  int secondsElapsed;

  TimerState(this.secondsElapsed);

  @override
  TimerState clone() => new TimerState(secondsElapsed);
}

class TimerWidget extends Widget<TimerState> {
  Timer timer;

  TimerWidget() {
    timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());

    willUnmount.listen((_) => timer.cancel());
  }

  tick() {
    nextState.secondsElapsed = state.secondsElapsed + 1;
  }

  Tag render() => $.Div(inner: "Seconds elapsed: ${state.secondsElapsed}");
}
