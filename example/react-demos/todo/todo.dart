import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new TagSet();
final TodoApp = new WidgetDef(make: () => new _TodoApp());

main() => root("#container").mount(TodoApp());

class _TodoState {
  String text;
  List<String> items;

  _TodoState(this.text, this.items);
}

class _TodoApp extends Widget<_TodoState> {

  void onPropsChange() {}

  @override
  _TodoState createFirstState() => new _TodoState('', []);

  void onChange(ChangeEvent e) {
    nextState.text = e.value;
  }

  void handleSubmit(HtmlEvent e) {
    nextState
      ..items = (new List.from(state.items)..add(state.text))
      ..text = "";
  }

  TagNode render() =>
    $.Div(inner: [
      $.H3(inner: "TODO"),
      _TodoList(items: state.items),
      $.Form(onSubmit: handleSubmit, inner: [
        $.Input(onChange: onChange, value: state.text),
        $.Button(inner: "Add # ${state.items.length + 1}")
      ])
    ]);

  _TodoState cloneState(_TodoState prev) => new _TodoState(prev.text, prev.items);
}

final _TodoList = new TemplateDef(
  render: ({List<String> items}) {
    createItem(itemText) => $.Li(inner: itemText);
    return $.Ul(inner: items.map(createItem));
  }
);
