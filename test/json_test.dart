import 'package:viewtree/core.dart';
import 'package:unittest/unittest.dart';

var $ = new Tags();

main() {
  test('serialize', () {
    Elt tree = $.Div(clazz: "something", inner: [
        $.H1(inner: "Hello!"),
        $.Span(innerHtml: "<h1>this</h1>")
        ]);
    String encoded = Elt.rules.encodeTree(tree);
    String expected = '["div",{"class":"something","inner":[0,["h1",{"inner":"Hello!"}],["span",{"innerHtml":"<h1>this</h1>"}]]}]';
    expect(encoded, equals(expected));
    Elt decoded = Elt.rules.decodeTree(encoded);
    expect(decoded.runtimeType, equals(Elt));
    Props p = decoded.props;
    expect(p.clazz, equals("something"));
    expect(p.inner, isList);
    expect(Elt.rules.encodeTree(decoded), equals(expected));
  });
}
