import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

class MarkdownEditor extends View {
  final String defaultText;
  const MarkdownEditor(this.defaultText);

  @override
  get animator => const _MarkdownEditor();
}

class _MarkdownEditor extends Animator<MarkdownEditor, String> {
  const _MarkdownEditor();

  @override
  firstState(MarkdownEditor view) => view.defaultText;

  View renderFrame(Place p) {
    String text = p.state;
    onChange(e) => p.step((_) => e.value);
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
