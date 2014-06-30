import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

class ReversableText extends AnimatedView<bool> {
  final String text;
  const ReversableText(this.text);

  @override
  get firstState => false;

  @override
  View renderFrame(Place<bool> p) {
    onClick(event) {
      p.nextState = !p.nextState;
    }

    var renderedText = p.state ? reverse(text) : text;

    return $.Div(clazz: "sample_text", onClick: onClick, inner: renderedText);
  }
}

String reverse(String text) {
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  return buffer.toString();
}

main() =>
    getRoot("#container")
      .mount(const ReversableText("Click me!"));
