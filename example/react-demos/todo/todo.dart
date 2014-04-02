import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

void main() {
  root("#container").mount(TodoApp());
}

final TodoApp = defineWidget(
    props: () => true,
    state: (_) => new _TodoState('', []),
    widget: () => new _TodoApp()
);

class _TodoState extends State {
  String text;
  List<String> items;

  _TodoState(this.text, this.items);

  @override
  clone() => new _TodoState(text, items);
}

class _TodoApp extends Widget<_TodoState> {

  void onChange(ChangeEvent e) {
    nextState.text = e.value;
  }

  void handleSubmit(ViewEvent e) {
    nextState
      ..items = (new List.from(state.items)..add(state.text))
      ..text = "";
  }

  Tag render() =>
    $.Div(inner: [
      $.H3(inner: "TODO"),
      _TodoList(items: state.items),
      $.Form(onSubmit: handleSubmit, inner: [
        $.Input(onChange: onChange, value: state.text),
        $.Button(inner: "Add # ${state.items.length + 1}")
      ])
    ]);
}

final _TodoList = defineTemplate(
  render: ({List<String> items}) {
    createItem(itemText) => $.Li(inner: itemText);
    return $.Ul(inner: items.map(createItem));
  }
);
