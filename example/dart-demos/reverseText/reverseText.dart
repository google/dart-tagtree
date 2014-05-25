import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new HtmlTagSet();
final ReversableText = new WidgetTag(make: () => new _ReversableText());

main() => root("#container").mount(ReversableText(label: "Click me!"));

class _ReversableText extends Widget<bool> {
  String label;

  onPropsChange({label}) {
    this.label = label;
  }

  @override
  bool createFirstState() => false;

  bool get reversed => state;
  String get text => reversed ? _reverse(label) : label;

  onClick(e) {
    nextState = !reversed;
  }

  TagNode render() => $.Div(clazz: "sample_text", onClick: onClick, inner: text);
}

String _reverse(String text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}
