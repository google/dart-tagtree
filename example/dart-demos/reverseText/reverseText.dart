import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

// Demonstrates how to switch between two templates.

class ReversableText extends View {
  final String text;
  const ReversableText(this.text);
  @override
  get defaultExpander => const _ForwardText();
}

class _ForwardText extends TemplateState<ReversableText> {
  const _ForwardText();

  @override
  isFirstState(Expander other) => other == this;

  @override
  render(view, refresh) {
    onClick(_) => refresh(const _ReversedText());
    return $.Div(clazz: "sample_text", onClick: onClick, inner: view.text);
  }
}

class _ReversedText extends TemplateState<ReversableText> {
  const _ReversedText();

  @override
  isFirstState(Expander other) => other == const _ForwardText();

  @override
  render(view, refresh) {
    onClick(_) => refresh(const _ForwardText());
    return $.Div(clazz: "sample_text", onClick: onClick, inner: reverse(view.text));
  }

  reverse(text) {
    var buffer = new StringBuffer();
    for (int i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}

main() =>
    getRoot("#container")
      .mount(const ReversableText("Click me!"));
