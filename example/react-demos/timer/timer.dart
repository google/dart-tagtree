import 'dart:async' show Timer;
import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

void main() {
  root("#container").mount(SecondsElapsed());
}

final SecondsElapsed = defineWidget(
    props: () => true,
    state: (_) => 0, // seconds
    widget: () => new TimerWidget()
);

final $ = new Tags();

class TimerWidget extends Widget<int> {
  Timer timer;

  TimerWidget() {
    timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());

    willUnmount.listen((_) => timer.cancel());
  }

  int get seconds => state;

  tick() {
    nextState = seconds + 1;
  }

  Tag render() => $.Div(inner: "Seconds elapsed: ${seconds}");
}
