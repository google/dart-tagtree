import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class HelloMessage extends View {
  final String name;
  const HelloMessage({this.name});
}

final helloTemplate = new Template((HelloMessage props) =>
    $.Div(inner: "Hello ${props.name}")
);

final theme = new Theme($)
    ..define(HelloMessage, () => helloTemplate);

main() =>
    getRoot("#container")
        ..mount(const HelloMessage(name: "World"), theme);
