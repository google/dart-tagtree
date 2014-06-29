part of browser;

/// A Ref provides access to the DOM element corresponding to a Tag.
/// To use it, pass it in as the "ref" parameter of a tag.
class Ref<E extends HtmlElement> {
  _ElementCache _cache;
  String _path;

  /// Returns the element, if mounted.
  E get elt => _cache.get(_path);
}

class _ElementCache {
  final HtmlElement container;
  final Map<String, HtmlElement> pathToNode = new HashMap();

  _ElementCache(this.container);

  HtmlElement get(String path) {
    HtmlElement node = pathToNode[path];
    if (node != null) {
      return node;
    }
    node = querySelector("[data-path=\"${path}\"]");
    if (node != null) {
      pathToNode[path] = node;
      return node;
    }
    return null;
  }

  void set(String path, HtmlElement elt) {
    pathToNode[path] = elt;
  }

  void clear(String path) {
    pathToNode.remove(path);
  }
}

class _DomUpdater implements render.DomUpdater {
  final _BrowserRoot root;

  _DomUpdater(this.root);

  _ElementCache get cache => root.eltCache;

  @override
  void mount(String html) {
    cache.container.setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  @override
  void attachRef(String refPath, ref) {
    if (ref is Ref) {
      ref._path = refPath;
      ref._cache = cache;
    }
  }

  @override
  void detachRef(ref) {
    if (ref is Ref) {
      ref._path = null;
      ref._cache = null;
    }
  }

  @override
  void mountForm(String formPath) {
    // onSubmit doesn't bubble, so install it here.
    FormElement elt = cache.get(formPath);
    root.formSubscriptions[formPath] = elt.onSubmit.listen((Event e) {
      String path = _getTargetPath(e.target);
      if (path != null) {
        e.preventDefault();
        e.stopPropagation();
        root.dispatchEvent(new HandlerEvent(onSubmit, path, null));
      }
    });
  }

  @override
  void detachElement(String path, ref, {bool willReplace: false}) {
    if (ref is Ref) {
      ref._cache = null;
    }
    StreamSubscription s = root.formSubscriptions[path];
    if (s != null) {
      s.cancel();
      root.formSubscriptions.remove(path);
    }
    if (!willReplace) {
      cache.clear(path);
    }
  }

  @override
  void replaceElement(String path, String html) {
    Element after = _newElement(html);
    _visit(path).replaceWith(after);
    cache.set(path, after);
  }

  @override
  void setAttribute(String path, String key, String value) {
    HtmlElement elt = _visit(path);
    elt.setAttribute(key, value);
    // Setting the "value" attribute on an input element doesn't actually change
    // what's in the text box.
    if (key == "value") {
      if (elt is InputElement) {
        elt.value = value;
      } else if (elt is TextAreaElement) {
        elt.value = value;
      }
    }
  }

  @override
  void removeAttribute(String path, String key) {
    _visit(path).attributes.remove(key);
  }

  @override
  void setInnerHtml(String path, String html) {
    _visit(path).setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  @override
  void setInnerText(String path, String text) {
    _visit(path).text = text;
  }

  @override
  void addChildElement(String path, String childHtml) {
    Element newElt = _newElement(childHtml);
    _visit(path).children.add(newElt);
  }

  @override
  void removeChild(String path, int index) {
    _visit(path).childNodes[index].remove();
  }

  HtmlElement _visit(String path) {
    assert(path != null);
    HtmlElement elt = cache.get(path);
    assert(elt != null);
    return elt;
  }

  HtmlElement _newElement(String html) {
    return new Element.html(html, treeSanitizer: _sanitizer);
  }
}

String _getTargetPath(EventTarget target) {
  if (target is Element) {
    return target.dataset["path"];
  } else {
    return null;
  }
}

String _getTargetValue(EventTarget target) {
  if (target is InputElement) {
    return target.value;
  } else if (target is TextAreaElement) {
    return target.value;
  } else {
    return null;
  }
}

/// A Dart HTML sanitizer that knows about data-path.
NodeTreeSanitizer _sanitizer = new NodeTreeSanitizer(new NodeValidatorBuilder()
    ..allowHtml5()
    ..add(new _AllowDataPath()));

class _AllowDataPath implements NodeValidator {
  bool allowsAttribute(Element elt, String att, String value) => att == "data-path";
  bool allowsElement(Element elt) => false;
}
