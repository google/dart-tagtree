import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

class MarkdownEditor extends View {
  final String defaultText;
  const MarkdownEditor(this.defaultText);

  @override
  createExpander() => new _MarkdownEditor();
}

class _MarkdownEditor extends Widget<MarkdownEditor, String> {

  @override
  getFirstState(MarkdownEditor view) => view.defaultText;

  get text => state;

  handleChange(e) {
    nextState = e.value;
  }

  @override
  render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: text),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", inner: new RawHtml(markdownToHtml(text))),
    ]);
}

main() =>
    getRoot("#container")
      ..mount(const MarkdownEditor("Type some *markdown* here!"));
