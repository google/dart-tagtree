import 'package:tagtree/core.dart';
import 'package:tagtree/html.dart';
import 'package:unittest/unittest.dart';

final $ = new HtmlTagSet();
final codec = $.makeCodec();

main() {
  test('serialize', () {
    View tree = $.Div(clazz: "something", inner: [
        $.H1(inner: "Hello!"),
        $.Span(innerHtml: "<h1>this</h1>")
        ]);
    String encoded = codec.encode(tree);
    String expected = '["div",{'
        '"class":"something",'
        '"inner":[0,'
          '["h1",{"inner":"Hello!"}],'
          '["span",{"innerHtml":"<h1>this</h1>"}]'
        ']'
    '}]';
    expect(encoded, equals(expected));
    View decoded = codec.decode(encoded);
    expect(decoded.tag, equals("div"));
    Props p = decoded.props;
    expect(p["class"], equals("something"));
    expect(p["inner"], isList);
    expect(codec.encode(decoded), equals(expected));
  });
}
