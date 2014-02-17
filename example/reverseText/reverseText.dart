import 'package:viewlet/core.dart';

var $ = new Tags();

void main() {
  mount(new Clicker("Click me!"), "#container");
}

class Clicker extends Widget {
  bool reversed = false;

  Clicker(value) : super({#value: value});

  get firstState => new ClickerState();
  ClickerState get state => super.state;
  ClickerState get nextState => super.nextState;

  onClick(e) {
    nextState
      ..reversed = !state.reversed;
  }

  View render() {
    var text = props[#value];
    if (state.reversed) {
      text = reverseString(props[#value]);
    }
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
