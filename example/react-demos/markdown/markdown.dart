import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

final $ = new HtmlTagSet();

class MarkdownEditor extends View {
  final String defaultText;
  const MarkdownEditor({this.defaultText});
}

main() =>
    root("#container")
      ..theme = theme
      ..mount(const MarkdownEditor(defaultText: "Type some *markdown* here!"));

final theme = new Theme()
  ..defineElements($)
  ..defineWidget(MarkdownEditor, () => new _MarkdownEditor());

class _MarkdownEditor extends Widget<MarkdownEditor, String> {
  MarkdownEditor view;

  @override
  setProps(MarkdownEditor view) {
    this.view = view;
  }

  @override
  String createFirstState() => view.defaultText;

  String get text => state;

  void handleChange(e) {
    nextState = e.value;
  }

  @override
  View render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: text),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", innerHtml: markdownToHtml(text)),
    ]);
}
