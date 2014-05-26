import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new HtmlTagSet();
final TodoApp = new WidgetTag(make: () => new _TodoApp());

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

  void onChange(HandlerEvent e) {
    nextState.text = e.value;
  }

  void handleSubmit(HandlerEvent e) {
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

final _TodoList = new TemplateTag(
  render: ({List<String> items}) {
    createItem(itemText) => $.Li(inner: itemText);
    return $.Ul(inner: items.map(createItem));
  }
);
