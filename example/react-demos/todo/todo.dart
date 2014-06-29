import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TodoList extends TemplateView {
  final List<String> items;
  const TodoList({this.items});

  @override
  render() {
    createItem(itemText) => $.Li(inner: itemText);
    return $.Ul(inner: items.map(createItem));
  }
}

class TodoApp extends View {
  const TodoApp();

  @override
  get animator => const _TodoApp();
}

class _TodoState implements Cloneable {
  List<String> items;
  String text;
  _TodoState(this.items, this.text);
  _TodoState clone() => new _TodoState(items, text);
}

class _TodoApp extends Animator<TodoApp, _TodoState> {

  const _TodoApp();

  @override
  firstState(_) => new _TodoState([], '');

  @override
  renderFrame(Place p) {

    onChange(HandlerEvent e) {
      p.nextState.text = e.value;
    }

    handleSubmit(HandlerEvent e) {
      p.nextState
        ..items = (new List.from(p.state.items)..add(p.state.text))
        ..text = "";
    }

    return $.Div(inner: [
      $.H3(inner: "TODO"),
      new TodoList(items: p.state.items),
      $.Form(onSubmit: handleSubmit, inner: [
        $.Input(onChange: onChange, value: p.state.text),
        $.Button(inner: "Add # ${p.state.items.length + 1}")
      ])
    ]);
  }
}

main() => getRoot("#container").mount(const TodoApp());

