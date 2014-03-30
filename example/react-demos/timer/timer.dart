import 'dart:async' show Timer;
import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

void main() {
  root("#container").mount(new TimerWidget());
}

class TimerWidget extends Widget<TimerState> {
  Timer timer;

  TimerWidget() : super({}) {
    didMount.listen((_) {
      timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());
    });

    willUnmount.listen((_) => timer.cancel());
  }

  get firstState => new TimerState();

  tick() {
    nextState.secondsElapsed = state.secondsElapsed + 1;
  }

  View render() => $.Div(inner: "Seconds elapsed: ${state.secondsElapsed}");
}

class TimerState extends State {
  int secondsElapsed = 0;

  TimerState clone() {
    return new TimerState()
      ..secondsElapsed = secondsElapsed;
  }
}