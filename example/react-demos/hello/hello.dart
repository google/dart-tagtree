import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

final Hello = new Template(
    render: ({String message}) => $.Div(inner: "Hello, ${message}")
);

void main() {
  root("#container").mount(Hello(message: "world"));
}
