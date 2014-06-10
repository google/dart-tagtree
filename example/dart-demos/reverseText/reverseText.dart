import 'package:tagtree/browser.dart';

var text = "Click me!";

render() => getRoot("#container").mount(
    $.Div(clazz: "sample_text", onClick: onClick, inner: text),
    $.elements);

onClick(_) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  text = buffer.toString();
  render();
}

main() => render();
