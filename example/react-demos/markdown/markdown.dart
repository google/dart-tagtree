import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

class MarkdownEditor extends View {
  final String defaultText;
  const MarkdownEditor(this.defaultText);

  @override
  get animation => const _MarkdownEditor();
}

class _MarkdownEditor extends Animation<MarkdownEditor, String> {
  const _MarkdownEditor();

  @override
  getFirstState(MarkdownEditor view) => view.defaultText;

  View expand(MarkdownEditor view, String text, Refresh refresh) {
    onChange(e) => refresh((_) => e.value);
    return $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: onChange, defaultValue: text),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", inner: new RawHtml(markdownToHtml(text))),
    ]);
  }

  @override
  shouldPlay(View next, Animation nextAnim) => next is MarkdownEditor && nextAnim == this;
}

main() =>
    getRoot("#container")
      ..mount(const MarkdownEditor("Type some *markdown* here!"));
