part of viewlet;

/// Encapsulates all DOM operations used to advance the view to the next frame.
class NextFrame {
  Element newElement(String html) {
    return new Element.html(html, treeSanitizer: _sanitizer);
  }

  void setInnerHtml(HtmlElement elt, String html) {
    elt.setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  void setInnerText(HtmlElement elt, String text) {
    elt.text = text;
  }

  void setAttribute(HtmlElement elt, String key, String value) {
    print("setting attribute: ${key}='${value}'");
    elt.setAttribute(key, value);
    // Setting the "value" attribute on an input element doesn't actually change what's in the text box.
    if (key == "value") {
      if (elt is InputElement) {
        elt.value = value;
      } else if(elt is TextAreaElement) {
        elt.value = value;
      }
    }
  }

  void removeAttribute(HtmlElement elt, String key) {
    elt.attributes.remove(key);
  }

  void replaceChildElement(HtmlElement elt, int index, String newHtml) {
    Element oldElt = elt.childNodes[index];
    Element newElt = newElement(newHtml);
    oldElt.replaceWith(newElt);
  }

  void addChildElement(HtmlElement elt, String childHtml) {
    Element newElt = newElement(childHtml);
    elt.children.add(newElt);
  }

  void removeChild(HtmlElement elt, int index) {
    elt.childNodes[index].remove();
  }
}

NodeTreeSanitizer _sanitizer = new NodeTreeSanitizer(new NodeValidatorBuilder()
    ..allowHtml5()
    ..add(new AllowDataPath()));

class AllowDataPath implements NodeValidator {
  bool allowsAttribute(Element elt, String att, String value) => att == "data-path";
  bool allowsElement(Element elt) => false;
}
