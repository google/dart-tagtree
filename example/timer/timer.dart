import 'dart:async' show Timer;
import 'package:viewlet/core.dart';

var $ = new Tags();

void main() {
  mount(new TimerWidget(), "#container");
}

class TimerWidget extends Widget {
  Timer timer;

  TimerWidget() : super({}) {
    didMount = () {
      timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());
    };
    willUnmount = () {
      timer.cancel();
    };
  }

  get firstState => new TimerState();
  TimerState get state => super.state;
  TimerState get nextState => super.nextState;

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