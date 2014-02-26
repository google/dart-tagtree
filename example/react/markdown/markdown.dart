import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;

var $ = new Tags();

void main() {
  mount(new MarkdownEditor(), "#container");
}

class MarkdownEditor extends Widget {
  MarkdownEditor() : super({});

  get firstState => new EditorState();
  EditorState get state => super.state;
  EditorState get nextState => super.nextState;

  void handleChange(e) {
    nextState.value = e.value;
  }

  View render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: state.value),
      $.H3(inner: "Output"),
      $.Div(clazz: "Content", innerHtml: markdownToHtml(state.value)),
    ]);
}

class EditorState extends State {
  String value = "Type some *markdown* here!";

  EditorState clone() =>
      new EditorState()
        ..value = this.value;
}
