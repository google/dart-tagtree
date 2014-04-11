import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

const $ = htmlTags;

main() => root("#container").mount(Hello(message: "world"));

final Hello = defineTemplate(
    render: ({String message}) => $.Div(inner: "Hello, ${message}")
);
