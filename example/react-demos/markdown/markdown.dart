import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;

void main() {
  root("#container").mount(MarkdownEditor(defaultText: "Type some *markdown* here!"));
}

final $ = new Tags();

final MarkdownEditor = defineWidget(
    props: ({String defaultText}) => true,
    widget: () => new _MarkdownEditor()
);

class _MarkdownEditor extends Widget<String> {
  String defaultText;

  onPropsChange({defaultText}) {
    this.defaultText = defaultText;
  }

  @override
  String createFirstState() => defaultText;

  String get text => state;

  void handleChange(e) {
    nextState = e.value;
  }

  Tag render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: text),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", innerHtml: markdownToHtml(text)),
    ]);
}
