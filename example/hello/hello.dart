import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

var $ = new Tags();

void main() {
  mount(new HelloMessage("world"), "#container");
}

class HelloMessage extends Widget {
  HelloMessage(String name) : super({#name: name});

  View render() =>
      $.Div(inner: "Hello, ${props.name}");
}