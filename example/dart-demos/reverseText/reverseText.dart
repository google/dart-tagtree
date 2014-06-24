import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

class ReversableText extends View {
  final String text;
  const ReversableText(this.text);
  @override
  get animation => const _ReversableText();
}

class _ReversableText extends Animation<ReversableText, bool> {
  const _ReversableText();

  @override
  getFirstState(_) => false;

  @override
  View expand(ReversableText view, bool reversed, Refresh refresh) {
    String text = reversed ? reverse(view.text) : view.text;
    onClick(_) => refresh((bool rev) => !rev);
    return $.Div(clazz: "sample_text", onClick: onClick, inner: text);
  }

  reverse(text) {
    var buffer = new StringBuffer();
    for (int i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  shouldPlay(View nextView, Animation nextAnim) => nextView is ReversableText && nextAnim == this;
}

main() =>
    getRoot("#container")
      .mount(const ReversableText("Click me!"));
