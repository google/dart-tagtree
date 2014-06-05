import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TodoList extends View {
  final List<String> items;
  const TodoList({this.items});
}

_renderTodoList(TodoList props) {
  createItem(itemText) => $.Li(inner: itemText);
  return $.Ul(inner: props.items.map(createItem));
}

class TodoApp extends View {
  const TodoApp();
}

class _TodoState {
  List<String> items;
  String text;
  _TodoState(this.items, this.text);
}

class _TodoApp extends Widget<TodoApp, _TodoState> {

  @override
  createFirstState() => new _TodoState([], '');

  onChange(HandlerEvent e) {
    nextState.text = e.value;
  }

  handleSubmit(HandlerEvent e) {
    nextState
      ..items = (new List.from(state.items)..add(state.text))
      ..text = "";
  }

  @override
  render() =>
    $.Div(inner: [
      $.H3(inner: "TODO"),
      new TodoList(items: state.items),
      $.Form(onSubmit: handleSubmit, inner: [
        $.Input(onChange: onChange, value: state.text),
        $.Button(inner: "Add # ${state.items.length + 1}")
      ])
    ]);

  @override
  cloneState(_TodoState prev) => new _TodoState(prev.items, prev.text);
}

main() =>
    getRoot("#container")
      ..theme.defineWidget(TodoApp, () => new _TodoApp())
      ..theme.defineTemplate(TodoList, _renderTodoList)
      ..mount(const TodoApp());
