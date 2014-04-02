import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;

void main() {
  root("#container").mount(MarkdownEditor(defaultText: "Type some *markdown* here!"));
}

final $ = new Tags();

final MarkdownEditor = defineWidget(
    props: ({String defaultText}) => true,
    state: (p) => new _EditorState(p.defaultText),
    widget: () => new _MarkdownEditor()
);

class _EditorState extends State {
  String value;

  _EditorState(this.value);

  _EditorState clone() => new _EditorState(value);
}

class _MarkdownEditor extends Widget<_EditorState> {

  void handleChange(e) {
    nextState.value = e.value;
  }

  Tag render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: state.value),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", innerHtml: markdownToHtml(state.value)),
    ]);
}
