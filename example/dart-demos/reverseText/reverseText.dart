import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

class ReversableText extends TaggedNode {
  get tag => "ReversableText";
  final String label;
  const ReversableText({this.label});
}

main() =>
    root("#container")
      ..addWidget("ReversableText", () => new _ReversableText())
      ..mount(const ReversableText(label: "Click me!"));

class _ReversableText extends Widget<ReversableText, bool> {
  String label;

  setProps(ReversableText node) {
    this.label = node.label;
  }

  @override
  bool createFirstState() => false;

  bool get reversed => state;
  String get text => reversed ? _reverse(label) : label;

  onClick(e) {
    nextState = !reversed;
  }

  ElementNode render() => $.Div(clazz: "sample_text", onClick: onClick, inner: text);
}

String _reverse(String text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}
