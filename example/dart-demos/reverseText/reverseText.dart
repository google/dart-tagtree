import 'package:tagtree/browser.dart';

const text = "Click me!";
final forward = clickable(text);
final reversed = clickable(reverse(text));
final root = getRoot("#container");

var current = forward;

clickable(text) =>
    $.Div(clazz: "sample_text", onClick: onClick, inner: text);

onClick(_) {
  current = (current == forward) ? reversed: forward;
  root.mount(current);
}

reverse(text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}

main() => root.mount(current);
