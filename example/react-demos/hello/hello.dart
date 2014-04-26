import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

main() => root("#container").mount(Hello(message: "world"));

final $ = new HtmlTagMaker();

final Hello = $.defineTemplate(
    render: ({String message}) => $.Div(inner: "Hello, ${message}")
);
