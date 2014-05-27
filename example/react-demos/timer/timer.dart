import 'dart:async' show Timer;
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();
final SecondsElapsed = new WidgetTag(make: () => new _SecondsElapsed());

main() => root("#container").mount(SecondsElapsed());

class _SecondsElapsed extends Widget<int> {
  Timer timer;

  _SecondsElapsed() {
    timer = new Timer.periodic(new Duration(seconds: 1), (t) => tick());

    willUnmount.listen((_) => timer.cancel());
  }

  setProps(TagNode node) {}

  @override
  int createFirstState() => 0;

  int get seconds => state;

  tick() {
    nextState = seconds + 1;
  }

  TagNode render() => $.Div(inner: "Seconds elapsed: ${seconds}");
}
