import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class HelloMessage extends TemplateTag {
  final String name;
  const HelloMessage({this.name});

  @override
  render() => $.Div(inner: "Hello ${name}");
}

main() =>
    getRoot("#container")
        ..mount(const HelloMessage(name: "World"));
