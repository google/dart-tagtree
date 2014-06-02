import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

class Hello extends TaggedNode {
  get tag => "Hello";
  final String message;
  const Hello({this.message});
}

main() =>
    root("#container", $)
        ..addTemplate("Hello", renderHello)
        ..mount(const Hello(message: "world"));

renderHello(Hello node) =>
    $.Div(inner: "Hello, ${node.message}");
