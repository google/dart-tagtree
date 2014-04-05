import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

void main() {
  root("#container").mount(ReversableText(label: "Click me!"));
}

final ReversableText = defineWidget(
  props: ({String label}) => true,
  widget: () => new _ReversableText()
);

class _ReversableText extends Widget<bool> {
  String label;

  onPropsChange({String label}) {
    this.label = label;
  }

  @override
  bool createFirstState() => false;

  bool get reversed => state;
  String get text => reversed ? _reverse(label) : label;

  onClick(e) {
    nextState = !reversed;
  }

  Tag render() => $.Div(clazz: "sample_text", onClick: onClick, inner: text);
}

String _reverse(String text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}
