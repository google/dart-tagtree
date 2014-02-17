import 'package:viewlet/core.dart';
import 'package:viewlet/browser.dart';

var $ = new Tags();

void main() {
  mount(new TodoApp(), "#container");
}

class TodoList extends Widget {
  TodoList({List<String> items}) : super({#items: items});

  View render() {
    createItem(itemText) => $.Li(inner: itemText);
    return $.Ul(inner: props[#items].map(createItem));
  }
}

class TodoApp extends Widget {
  TodoApp() : super({});

  get firstState => new TodoState();
  TodoState get state => super.state;
  TodoState get nextState => super.nextState;

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
      new TodoList(items: state.items),
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