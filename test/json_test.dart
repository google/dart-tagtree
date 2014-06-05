import 'package:tagtree/core.dart';
import 'package:tagtree/html.dart';
import 'package:unittest/unittest.dart';

final $ = new HtmlTagSet();
final codec = $.makeCodec();

main() {
  test('serialize', () {
    View tree = $.Div(clazz: "something", inner: [
        $.H1(inner: "Hello!"),
        $.Span(inner: new RawHtml("<h1>this</h1>"))
        ]);
    String encoded = codec.encode(tree);
    String expected = '["div",{'
        '"class":"something",'
        '"inner":[0,'
          '["h1",{"inner":"Hello!"}],'
          '["span",{"inner":["rawHtml","<h1>this</h1>"]}]'
        ']'
    '}]';
    expect(encoded, equals(expected));
    View decoded = codec.decode(encoded);
    expect(decoded.tag, equals("div"));
    expect(decoded.props.keys, equals(["class", "inner"]));
    expect(decoded.props["class"], equals("something"));
    expect(decoded.props["inner"], isList);
    View span = decoded.props["inner"][1];
    expect(span.tag, equals("span"));
    expect(span.props.keys, equals(["inner"]));
    RawHtml html = span.props["inner"];
    expect(html.html, equals("<h1>this</h1>"));
    expect(codec.encode(decoded), equals(expected));
  });
}
