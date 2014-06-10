import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

class MarkdownEditor extends View {
  const MarkdownEditor();
}

class _MarkdownEditor extends Widget<MarkdownEditor, String> {

  @override
  createFirstState() => "Type some *markdown* here!";

  get value => state;

  handleChange(e) {
    nextState = e.value;
  }

  @override
  render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: value),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", inner: new RawHtml(markdownToHtml(value))),
    ]);
}

final theme = $.elements.extend({MarkdownEditor: () => new _MarkdownEditor()});

main() =>
    getRoot("#container")
      ..mount(const MarkdownEditor(), theme);
