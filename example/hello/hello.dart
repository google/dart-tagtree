import 'dart:html';
import '../../lib/viewlet.dart';

var $ = new Tags();

void main() {
  mount(new HelloMessage(name: "world"), querySelector("#container"));
}

class HelloMessage extends Widget {
  HelloMessage({String name}) : super({#name: name});
  View render() => $.Div(inner: "Hello, ${props[#name]}");
}