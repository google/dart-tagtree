library browser;

import 'package:viewlet/core.dart' as core;
import 'dart:html';
import 'dart:collection' show HashMap;

var _context = new BrowserContext();

void mount(core.View tree, String domQuery) => core.coreMount(_context, tree, domQuery);

class BrowserContext implements core.Context {

  @override
  void listenForEvents(String domQuery) {
    HtmlElement container = querySelector(domQuery);
    // Form events are tricky. We want an onChange event to fire every time
    // the value in a text box changes. The native 'input' event does this,
    // not 'change' which only fires after focus is lost.
    // In React, see ChangeEventPlugin.
    // TODO: support IE9.
    container.onInput.listen((Event e) {
      var target = e.target;
      String value;
      if (target is InputElement) {
        value = target.value;
      }
      if (target is TextAreaElement) {
        value = target.value;
      }
      core.dispatchEvent(new core.ChangeEvent(getTargetPath(e), value));
    });

    container.onClick.listen((Event e) {
        core.dispatchEvent(new core.ViewEvent(#onClick, getTargetPath(e)));
    });
    container.onSubmit.listen((Event e) {
        core.dispatchEvent(new core.ViewEvent(#onSubmit, getTargetPath(e)));
    });
  }

  @override
  core.NextFrame nextFrame() => new NextFrameImpl();

  @override
  void didMountForm(String path) {
    FormElement elt = elementCache.get(path);
    elt.onSubmit.listen((Event e) {
      print("form submitted: ${path}");
      e.preventDefault();
      e.stopPropagation();
      core.dispatchEvent(new core.ViewEvent(#onSubmit, getTargetPath(e)));
    });
  }

  @override
  void onUnmount(String path) {
    elementCache._clear(path);
  }

  @override
  void requestAnimationFrame(callback) {
    window.animationFrame.then(callback);
  }
}

String getTargetPath(Event e) {
  var target = e.target;
  if (target is Element) {
    return target.dataset["path"];
  } else {
    return null;
  }
}

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
class NextFrameImpl implements core.NextFrame {
  HtmlElement _elt;

  void mount(String domQuery, String html) {
    HtmlElement container = querySelector(domQuery);
    container.setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  void detachElement(String path) {
    elementCache._clear(path);
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
