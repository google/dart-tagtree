import 'package:viewlet/core.dart';
import 'package:viewlet/browser.dart';

var $ = new Tags();

void main() {
  mount(new HelloMessage("world"), "#container");
}

class HelloMessage extends Widget {
  HelloMessage(String name) : super({#name: name});

  View render() =>
      $.Div(inner: "Hello, ${props.name}");
}