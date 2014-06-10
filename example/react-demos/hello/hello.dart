import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class HelloMessage extends View {
  final String name;
  const HelloMessage({this.name});
}

class _HelloMessage extends Template {
  const _HelloMessage();
  @override
  render(HelloMessage props) => $.Div(inner: "Hello ${props.name}");
}

final tags = $.elements.extend(const {
  HelloMessage: const _HelloMessage()
});

main() =>
    getRoot("#container")
        ..mount(const HelloMessage(name: "World"), tags);
