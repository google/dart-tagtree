import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class HelloMessage extends View {
  final String name;
  const HelloMessage({this.name});

  @override
  createViewer() => const _HelloMessage();
}

class _HelloMessage extends Template {
  const _HelloMessage();

  @override
  render(HelloMessage props) => $.Div(inner: "Hello ${props.name}");
}

main() =>
    getRoot("#container")
        ..mount(const HelloMessage(name: "World"));
