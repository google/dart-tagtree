import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

class Hello extends View {
  @override
  get tag => "Hello";

  final String message;
  const Hello({this.message});
}

final theme = new Theme()
  ..addElements($)
  ..addTemplate("Hello", renderHello);

renderHello(Hello view) =>
    $.Div(inner: "Hello, ${view.message}");

main() =>
    root("#container")
        ..theme = theme
        ..mount(const Hello(message: "world"));

