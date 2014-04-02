import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

void main() {
  root("#container").mount(ReversableText(label: "Click me!"));
}

final $ = new Tags();

final ReversableText = defineWidget(
    props: ({String label}) => true,
    state: (_) => false,
    widget: () => new _ReversableText()
);

class _ReversableText extends Widget<bool> {

  bool get reversed => state;

  onClick(e) {
    nextState = !reversed;
  }

  Tag render() {
    String label = props.label;
    label = reversed ? _reverse(label) : label;
    return $.Div(clazz: "sample_text", onClick: onClick, inner: label);
  }
}

String _reverse(String text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}
