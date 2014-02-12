part of viewlet;

void setInnerHtml(HtmlElement elt, String html) {
  elt.setInnerHtml(html, treeSanitizer: _sanitizer);
}

Element newElement(String html) {
  return new Element.html(html, treeSanitizer: _sanitizer);
}

NodeTreeSanitizer _sanitizer = new NodeTreeSanitizer(new NodeValidatorBuilder()
    ..allowHtml5()
    ..add(new AllowDataPath()));

class AllowDataPath implements NodeValidator {
  bool allowsAttribute(Element elt, String att, String value) => att == "data-path";
  bool allowsElement(Element elt) => false;
}
