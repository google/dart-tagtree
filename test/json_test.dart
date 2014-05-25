import 'package:viewtree/core.dart';
import 'package:viewtree/json.dart';
import 'package:unittest/unittest.dart';

final $ = new HtmlTagSet();
final codec = makeCodec($);

main() {
  test('serialize', () {
    TagNode tree = $.Div(clazz: "something", inner: [
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
    TagNode decoded = codec.decode(encoded);
    ElementTag def = decoded.tag;
    expect(def.type.name, equals("div"));
    var p = decoded.props;
    expect(p.clazz, equals("something"));
    expect(p.inner, isList);
    expect(codec.encode(decoded), equals(expected));
  });
}
