import 'package:viewtree/core.dart';
import 'package:unittest/unittest.dart';

final $ = new HtmlTagMaker();

main() {
  test('serialize', () {
    Tag tree = $.Div(clazz: "something", inner: [
        $.H1(inner: "Hello!"),
        $.Span(innerHtml: "<h1>this</h1>")
        ]);
    String encoded = htmlCodec.encode(tree);
    String expected = '["div",{'
        '"class":"something",'
        '"inner":[0,'
          '["h1",{"inner":"Hello!"}],'
          '["span",{"innerHtml":"<h1>this</h1>"}]'
        ']'
    '}]';
    expect(encoded, equals(expected));
    Tag decoded = htmlCodec.decode(encoded);
    EltDef def = decoded.def;
    expect("div", equals(def.tagName));
    var p = decoded.props;
    expect(p.clazz, equals("something"));
    expect(p.inner, isList);
    expect(htmlCodec.encode(decoded), equals(expected));
  });
}
