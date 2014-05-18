import 'dart:async' show Timer;
import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new TagMaker();
final SecondsElapsed = new WidgetDef(make: () => new _SecondsElapsed());

main() => root("#container").mount(SecondsElapsed());

class _SecondsElapsed extends Widget<int> {
  Timer timer;

  _SecondsElapsed() {
    timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());

    willUnmount.listen((_) => timer.cancel());
  }

  onPropsChange() {}

  @override
  int createFirstState() => 0;

  int get seconds => state;

  tick() {
    nextState = seconds + 1;
  }

  Tag render() => $.Div(inner: "Seconds elapsed: ${seconds}");
}
