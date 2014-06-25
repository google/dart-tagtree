import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

// This example shows a very simple animation that displays some text.
// It runs forever and renders a new animation frame whenever the user clicks on it.
// There are only two frames, forward and reversed.

class ReversableText extends View {
  final String text;
  const ReversableText(this.text);
  @override
  get animation => const _ReversableText();
}

class _ReversableText extends Animation<ReversableText, bool> {
  const _ReversableText();

  @override
  firstState(view) => false;

  @override
  View renderFrame(Place p) {
    onClick(event) => p.nextFrame(toggle);

    bool isReversed = p.state;

    var text = p.view.text;
    if (isReversed) {
      text = reverse(text);
    }

    return $.Div(clazz: "sample_text", onClick: onClick, inner: text);
  }

  toggle(bool reversed) => !reversed;

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
