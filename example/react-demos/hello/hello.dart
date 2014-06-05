import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class HelloMessage extends View {
  final String name;
  const HelloMessage({this.name});
}

renderHello(HelloMessage props) => $.Div(inner: "Hello ${props.name}");

main() =>
    getRoot("#container")
        ..theme.defineTemplate(HelloMessage, renderHello)
        ..mount(const HelloMessage(name: "World"));

