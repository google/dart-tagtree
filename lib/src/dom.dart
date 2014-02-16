part of viewlet;

ElementCache elementCache = new ElementCache();

class ElementCache {
  Map<String, HtmlElement> idToNode = new HashMap();

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


/// Encapsulates all operations used to update the DOM to the next frame.
class NextFrame {
  HtmlElement _elt;

  void mount(HtmlElement container, String html) {
    container.setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  /// Visits the element at the given path. Other methods act on the current element.
  void visit(String path) {
    _elt = elementCache.get(path);
    assert(_elt is HtmlElement);
  }

  void replaceElement(String html) {
    Element after = _newElement(html);
    _elt.replaceWith(after);
  }

  void setAttribute(String key, String value) {
    print("setting attribute: ${key}='${value}'");
    _elt.setAttribute(key, value);
    // Setting the "value" attribute on an input element doesn't actually change what's in the text box.
    if (key == "value") {
      HtmlElement elt = _elt;
      if (elt is InputElement) {
        elt.value = value;
      } else if(elt is TextAreaElement) {
        elt.value = value;
      }
    }
  }

  void removeAttribute(String key) {
    _elt.attributes.remove(key);
  }

  void setInnerHtml(String html) {
    _elt.setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  void setInnerText(String text) {
    _elt.text = text;
  }

  void replaceChildElement(int index, String newHtml) {
    Element oldElt = _elt.childNodes[index];
    Element newElt = _newElement(newHtml);
    oldElt.replaceWith(newElt);
  }

  void addChildElement(String childHtml) {
    Element newElt = _newElement(childHtml);
    _elt.children.add(newElt);
  }

  void removeChild(int index) {
    _elt.childNodes[index].remove();
  }

  HtmlElement _newElement(String html) {
    return new Element.html(html, treeSanitizer: _sanitizer);
  }
}

NodeTreeSanitizer _sanitizer = new NodeTreeSanitizer(new NodeValidatorBuilder()
    ..allowHtml5()
    ..add(new AllowDataPath()));

class AllowDataPath implements NodeValidator {
  bool allowsAttribute(Element elt, String att, String value) => att == "data-path";
  bool allowsElement(Element elt) => false;
}
