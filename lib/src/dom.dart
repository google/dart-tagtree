part of viewlet;

ElementCache elementCache = new ElementCache();

class ElementCache {
  Map<String, HtmlElement> idToNode = {};

  HtmlElement get(String path) {
    HtmlElement node = idToNode[path];
    if (node != null) {
      return node;
    }
    node = querySelector("[data-path=\"${path}\"]");
    if (node != null) {
      idToNode[path] = node;
      return node;
    }
    return null;
  }

  void _set(String path, HtmlElement elt) {
    idToNode[path] = elt;
  }

  void _clear(String path) {
    idToNode.remove(path);
  }
}


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

  void replaceElement(Element elt, String html) {
    Element after = newElement(html);
    elt.replaceWith(after);
  }
}

NodeTreeSanitizer _sanitizer = new NodeTreeSanitizer(new NodeValidatorBuilder()
    ..allowHtml5()
    ..add(new AllowDataPath()));

class AllowDataPath implements NodeValidator {
  bool allowsAttribute(Element elt, String att, String value) => att == "data-path";
  bool allowsElement(Element elt) => false;
}
