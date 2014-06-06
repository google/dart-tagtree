import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class HelloMessage extends View {
  final String name;
  const HelloMessage({this.name});
}

final template = new Template(HelloMessage,
    (props) => $.Div(inner: "Hello ${props.name}")
);

main() =>
    getRoot("#container")
        ..theme.add(template)
        ..mount(const HelloMessage(name: "World"));

