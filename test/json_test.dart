import 'package:viewtree/core.dart';
import 'package:unittest/unittest.dart';

const $ = htmlTags;

main() {
  test('serialize', () {
    Tag tree = $.Div(clazz: "something", inner: [
        $.H1(inner: "Hello!"),
        $.Span(innerHtml: "<h1>this</h1>")
        ]);
    String encoded = htmlCodec.encode(tree);
    String expected = '["div",{"class":"something","inner":[0,["h1",{"inner":"Hello!"}],["span",{"innerHtml":"<h1>this</h1>"}]]}]';
    expect(encoded, equals(expected));
    EltTag decoded = htmlCodec.decode(encoded);
    expect(decoded.runtimeType, equals(EltTag));
    Props p = new Props(decoded.props);
    expect(p.clazz, equals("something"));
    expect(p.inner, isList);
    expect(htmlCodec.encode(decoded), equals(expected));
  });
}
