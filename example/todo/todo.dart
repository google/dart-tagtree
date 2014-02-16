import 'dart:html';
import '../../lib/viewlet.dart';

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

  void onChange(Event e) {
    InputElement target = e.target;
    nextState
      ..text = target.value;
    print("changed text to: ${target.value}");
  }

  void handleSubmit(Event e) {
    e.preventDefault();
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