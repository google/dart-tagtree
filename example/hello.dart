import 'dart:html';
import '../lib/viewlet.dart';

var $ = new Tags();

void main() {
  var clicker = new Clicker("Click me!");
  mount(clicker, querySelector("#sample_container_id"));
}

class Clicker extends Widget {
  bool reversed = false;

  Clicker(value) : super({#value: value});

  get firstState => {#reversed: false};

  onClick(e) {
    setState({#reversed: !state[#reversed]});
  }

  View render() {
    var text = props[#value];
    if (state[#reversed]) {
      text = reverseString(props[#value]);
    }
    return $.Div(clazz: "sample_text", onClick: onClick, inner: text);
  }
}

String reverseString(String text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}
