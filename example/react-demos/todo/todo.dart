import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

final TodoApp = new TagDef(
  widget: (_) => new TodoAppWidget()
);

final TodoList = new TagDef(
  render: ({List<String> items}) {
    createItem(itemText) => $.Li(inner: itemText);
    return $.Ul(inner: items.map(createItem));
  }
);

void main() {
  root("#container").mount(TodoApp());
}

class TodoAppWidget extends Widget<TodoState> {
  TodoAppWidget() : super({});

  get firstState => new TodoState();

  void onChange(ChangeEvent e) {
    nextState.text = e.value;
  }

  void handleSubmit(ViewEvent e) {
    nextState
      ..items = (new List.from(state.items)..add(state.text))
      ..text = "";
  }

  View render() =>
    $.Div(inner: [
      $.H3(inner: "TODO"),
      TodoList(items: state.items),
      $.Form(onSubmit: handleSubmit, inner: [
        $.Input(onChange: onChange, value: state.text),
        $.Button(inner: "Add # ${state.items.length + 1}")
      ])
    ]);
}

class TodoState extends State {
  String text = '';
  List<String> items = [];
  clone() => new TodoState()
    ..items = items
    ..text = text;
}