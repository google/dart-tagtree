import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

class MarkdownEditor extends AnimatedView<String> {
  final String defaultText;
  const MarkdownEditor(this.defaultText);

  @override
  start() => new Place<String>(defaultText);

  View renderAt(Place<String> p) {
    String text = p.state;

    onChange(e) {
      p.nextState = e.value;
    }

    return $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: onChange, defaultValue: text),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", inner: new RawHtml(markdownToHtml(text))),
    ]);
  }
}

main() =>
    getRoot("#container")
      ..mount(const MarkdownEditor("Type some *markdown* here!"));
