import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

void main() {
  root("#container").mount(ReversableText(label: "Click me!"));
}

final $ = new Tags();

final ReversableText = defineWidget(
    props: ({String label}) => true,
    state: (_) => new _ReversableState(false),
    widget: () => new _ReversableText()
);

class _ReversableState extends State {
  bool reversed;
  _ReversableState(this.reversed);
  clone() => new _ReversableState(reversed);
}

class _ReversableText extends Widget<_ReversableState> {

  onClick(e) {
    nextState.reversed = !state.reversed;
  }

  Tag render() {
    String label = props.label;
    label = state.reversed ? _reverse(label) : label;
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
