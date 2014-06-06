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
    ElementView decoded = codec.decode(encoded);
    expect(decoded.htmlTag, equals("div"));
    expect(decoded.props.keys, equals(["class", "inner"]));
    expect(decoded.props["class"], equals("something"));
    expect(decoded.inner, isList);
    ElementView span = decoded.inner[1];
    expect(span.htmlTag, equals("span"));
    expect(span.props.keys, equals(["inner"]));
    RawHtml html = span.inner;
    expect(html.html, equals("<h1>this</h1>"));
    expect(codec.encode(decoded), equals(expected));
  });
}
