import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

void main() {
  root("#container").mount(Hello(message: "world"));
}

final Hello = defineTemplate(
    render: ({String message}) => $.Div(inner: "Hello, ${message}")
);
