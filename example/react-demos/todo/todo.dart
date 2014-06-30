import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class TodoList extends TemplateView {
  final List<String> items;
  const TodoList(this.items);

  @override
  render() {
    createItem(itemText) => $.Li(inner: itemText);
    return $.Ul(inner: items.map(createItem));
  }
}

class TodoApp extends AnimatedView<_TodoState> {
  const TodoApp();

  @override
  get firstState => new _TodoState([], '');

  @override
  renderFrame(Place<_TodoState> p) {

    onChange(HandlerEvent e) {
      p.nextState.text = e.value;
    }

    handleSubmit(HandlerEvent e) {
      var nextItems = new List.from(p.state.items)..add(p.state.text);
      var nextText = "";
      p.nextState = new _TodoState(nextItems, nextText);
    }

    return $.Div(inner: [
      $.H3(inner: "TODO"),
      new TodoList(p.state.items),
      $.Form(onSubmit: handleSubmit, inner: [
        $.Input(onChange: onChange, value: p.state.text),
        $.Button(inner: "Add # ${p.state.items.length + 1}")
      ])
    ]);
  }
}

class _TodoState implements Cloneable {
  List<String> items;
  String text;
  _TodoState(this.items, this.text);
  _TodoState clone() => new _TodoState(items, text);
}

main() => getRoot("#container").mount(const TodoApp());

