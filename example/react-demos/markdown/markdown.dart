import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;

final $ = new HtmlTagSet();
final MarkdownEditor = new WidgetTag(make: () => new _MarkdownEditor());

main() => root("#container").mount(MarkdownEditor(defaultText: "Type some *markdown* here!"));

class _MarkdownEditor extends Widget<String> {
  String defaultText;

  setProps(TagNode node) {
    this.defaultText = node.props.defaultText;
  }

  @override
  String createFirstState() => defaultText;

  String get text => state;

  void handleChange(e) {
    nextState = e.value;
  }

  TagNode render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: text),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", innerHtml: markdownToHtml(text)),
    ]);
}
