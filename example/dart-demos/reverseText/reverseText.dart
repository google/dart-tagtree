import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

class ReversableText extends View {
  @override
  get tag => "ReversableText";

  final String label;
  const ReversableText({this.label});
}

main() =>
    root("#container", $)
      ..addWidget("ReversableText", () => new _ReversableText())
      ..mount(const ReversableText(label: "Click me!"));

class _ReversableText extends Widget<ReversableText, bool> {
  ReversableText view;

  @override
  setProps(ReversableText view) {
    this.view = view;
  }

  @override
  bool createFirstState() => false;

  bool get isReversed => state;
  String get text => isReversed ? _reverse(view.label) : view.label;

  onClick(e) {
    nextState = !isReversed;
  }

  @override
  View render() => $.Div(clazz: "sample_text", onClick: onClick, inner: text);
}

String _reverse(String text) {
  var out = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    out.write(text[i]);
  }
  return out.toString();
}
