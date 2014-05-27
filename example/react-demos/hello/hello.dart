import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

final $ = new HtmlTagSet();

final Hello = new TemplateTag(
    render: ({String message}) => $.Div(inner: "Hello, ${message}")
);

main() => root("#container").mount(Hello(message: "world"));
