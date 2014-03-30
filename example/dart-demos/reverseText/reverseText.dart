import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

var $ = new Tags();

void main() {
  root("#container").mount(new Clicker("Click me!"));
}

class Clicker extends Widget {
  Clicker(label) : super({#label: label});

  get firstState => new ClickerState();
  ClickerState get state => super.state;
  ClickerState get nextState => super.nextState;

  onClick(e) {
    nextState.reversed = !state.reversed;
  }

  View render() {
    var text = state.reversed ? reverseString(props.label) : props.label;
    return $.Div(clazz: "sample_text", onClick: onClick, inner: text);
  }
}

class ClickerState extends State {
  bool reversed = false;

  State clone() {
    return new ClickerState()
      ..reversed = reversed;
  }
}

String reverseString(String text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}
