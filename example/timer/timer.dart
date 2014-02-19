import 'dart:async' show Timer;
import 'package:viewlet/core.dart';
import 'package:viewlet/browser.dart';

var $ = new Tags();

void main() {
  mount(new TimerWidget(), "#container");
}

class TimerWidget extends Widget {
  Timer timer;

  TimerWidget() : super({});

  get firstState => new TimerState();
  TimerState get state => super.state;
  TimerState get nextState => super.nextState;

  didMount() {
    timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());
  }

  willUnmount() {
    timer.cancel();
  }

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