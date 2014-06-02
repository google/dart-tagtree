import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

final $ = new HtmlTagSet();

class MarkdownEditor extends TaggedNode {
  get tag => "MarkdownEditor";
  final String defaultText;
  const MarkdownEditor({this.defaultText});
}

main() =>
    root("#container", $)
      ..addWidget("MarkdownEditor", () => new _MarkdownEditor())
      ..mount(const MarkdownEditor(defaultText: "Type some *markdown* here!"));

class _MarkdownEditor extends Widget<MarkdownEditor, String> {
  String defaultText;

  setProps(MarkdownEditor node) {
    this.defaultText = node.defaultText;
  }

  @override
  String createFirstState() => defaultText;

  String get text => state;

  void handleChange(e) {
    nextState = e.value;
  }

  ElementNode render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: text),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", innerHtml: markdownToHtml(text)),
    ]);
}
