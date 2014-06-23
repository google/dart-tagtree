import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

// Demonstrates how to implement a view using a state machine.

class MarkdownEditor extends View {
  final String defaultText;
  const MarkdownEditor(this.defaultText);

  @override
  get defaultExpander => new _EditorState.first(defaultText);
}

class _EditorState extends TemplateState<MarkdownEditor> {
  final String firstText;
  final String text;

  _EditorState.first(String text) : firstText = text, this.text = text;

  _EditorState.next(this.firstText, this.text);

  @override
  isFirstState(Expander other) => other is _EditorState && other.text == firstText;

  @override
  render(View view, Refresh refresh) {
    onChange(e) {
      refresh(new _EditorState.next(firstText, e.value));
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
