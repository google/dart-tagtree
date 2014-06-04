import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

class TodoApp extends View {
  @override
  get tag => "TodoApp";

  const TodoApp();
}

class TodoList extends View {
  @override
  get tag => "TodoList";

  final List<String> items;
  const TodoList({this.items});
}

main() =>
    root("#container")
      ..theme = theme
      ..mount(const TodoApp());

final theme = new Theme($)
    ..addWidget("TodoApp", () => new _TodoApp())
    ..addTemplate("TodoList", _renderTodoList);

class _TodoState {
  String text;
  List<String> items;

  _TodoState(this.text, this.items);
}

class _TodoApp extends Widget<TodoApp, _TodoState> {

  @override
  void setProps(_) {}

  @override
  _TodoState createFirstState() => new _TodoState('', []);

  void onChange(HandlerEvent e) {
    nextState.text = e.value;
  }

  void handleSubmit(HandlerEvent e) {
    nextState
      ..items = (new List.from(state.items)..add(state.text))
      ..text = "";
  }

  @override
  View render() =>
    $.Div(inner: [
      $.H3(inner: "TODO"),
      new TodoList(items: state.items),
      $.Form(onSubmit: handleSubmit, inner: [
        $.Input(onChange: onChange, value: state.text),
        $.Button(inner: "Add # ${state.items.length + 1}")
      ])
    ]);

  @override
  _TodoState cloneState(_TodoState prev) => new _TodoState(prev.text, prev.items);
}

View _renderTodoList(TodoList node) {
  createItem(itemText) => $.Li(inner: itemText);
  return $.Ul(inner: node.items.map(createItem));
}
