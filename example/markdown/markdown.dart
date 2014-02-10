import 'dart:html';
import '../../lib/viewlet.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;

var $ = new Tags();

void main() {
  mount(new MarkdownEditor(), querySelector("#container"));
}

class MarkdownEditor extends Widget {
  var _textArea = new Ref();

  MarkdownEditor() : super({});

  get firstState => new EditorState();
  EditorState get state => super.state;
  EditorState get nextState => super.nextState;
  TextAreaElement get textArea => _textArea.getDom();

  void handleChange(e) {
    nextState.value = textArea.value;
  }

  View render() =>
    $.Div(clazz: "MarkdownEditor", inner: [
      $.H3(inner: "Input"),
      $.TextArea(onChange: handleChange, defaultValue: state.value, ref: _textArea),
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
