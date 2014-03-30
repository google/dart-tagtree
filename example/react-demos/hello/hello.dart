import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

void main() {
  root("#container").mount(new HelloMessage("world"));
}

class HelloMessage extends Widget {
  HelloMessage(String name) : super({#name: name});

  View render() =>
      $.Div(inner: "Hello, ${props.name}");
}