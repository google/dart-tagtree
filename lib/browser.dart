/**
 * Glue code connecting the ViewTree core (which is browser-independent) to the dart:html library.
 */
library browser;

import 'package:viewtree/core.dart' as core;

import 'dart:async' show StreamSubscription;
import 'dart:html';
import 'dart:collection' show HashMap;

int _treeIdCounter = 0;

Map<String, core.ViewTree> _idToTree = {};

/// Starts running a View.
///
/// The CSS selectors must point to a single HtmlElement.
/// If the element already contains a View, it will be updated or replaced.
/// Renders the first frame inside the container, then starts listening for events.
/// Postcondition: all Views under root are mounted and rendered.
void mount(core.View root, String selectors) {
  HtmlElement container = querySelectorAll(selectors).single;
  var prev = getTreeByContainer(container);
  if (prev != null) {
    prev.replaceRoot(root);
    return;
  }
  _ElementCache cache = new _ElementCache(container);
  int id = _treeIdCounter++;
  core.ViewTree tree = new core.ViewTree.mount(id, new _BrowserEnv(cache), root, new _SyncFrame(cache));
  _listenForEvents(tree, container);
}

core.ViewTree getTreeByContainer(HtmlElement container) {
  var first = container.firstChild;
  if (first == null) {
    return null;
  }
  if (first is Element) {
    String id = first.getAttribute("data-path");
    if (id != null) {
      return _idToTree[id];
    }
  }
  return null;
}

/// A reference that also allows access to the DOM Element corresponding
/// to a View.
class ElementRef<E extends HtmlElement> extends core.Ref {
  _ElementCache cache;

  /// Returns the element, if mounted.
  E get elt => cache.get(view.path);

  onDetach() {
    cache = null;
  }
}

void _listenForEvents(core.ViewTree tree, HtmlElement container) {

  container.onClick.listen((Event e) {
    String path = _getTargetPath(e.target);
    if (path == null) {
      return;
    }
    tree.dispatchEvent(new core.ViewEvent(#onClick, path));
  });

  // Form events are tricky. We want an onChange event to fire every time
  // the value in a text box changes. The native 'input' event does this,
  // not 'change' which only fires after focus is lost.
  // TODO: support IE9 (not tested other than in Chrome).
  // (See ChangeEventPlugin in React for browser-specific workarounds.)
  container.onInput.listen((Event e) {
    String path = _getTargetPath(e.target);
    if (path == null) {
      return;
    }
    String value = _getTargetValue(e.target);
    if (value == null) {
      print("can't get value of target: ${path}");
      return;
    }
    tree.dispatchEvent(new core.ChangeEvent(path, value));
  });

  // TODO: implement many more events.
  // TODO: remove handlers on unmount.
}

class _BrowserEnv implements core.TreeEnv {
  final _ElementCache cache;

  _BrowserEnv(this.cache);

  @override
  void requestFrame(core.ViewTree tree) {
    window.animationFrame.then((t) {
      tree.render(new _SyncFrame(cache));
    });
  }
}

class _ElementCache {
  final HtmlElement container;
  final Map<String, HtmlElement> idToNode = new HashMap();

  _ElementCache(this.container);

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

/// An implementation of NextFrame that applies frame mutations immediately to the DOM.
class _SyncFrame implements core.NextFrame {

  final _ElementCache cache;
  final Map<String, StreamSubscription> formSubscriptions = {};

  /// The current element. Most methods operate on this element.
  HtmlElement _elt;
  String _path;

  _SyncFrame(this.cache);

  @override
  void mount(String html) {
    cache.container.setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  @override
  void attachElement(core.ViewTree tree, core.Ref ref, String path, String tag) {
    if (tag == "form") {
      // onSubmit doesn't bubble, so install it here.
      FormElement elt = cache.get(path);
      formSubscriptions[path] = elt.onSubmit.listen((Event e) {
        String path = _getTargetPath(e.target);
        if (path == null) {
          return;
        }
        e.preventDefault();
        e.stopPropagation();
        tree.dispatchEvent(new core.ViewEvent(#onSubmit, path));
      });
    }
    if (ref is ElementRef) {
      ref.cache = cache;
    }
  }

  @override
  void detachElement(String path) {
    StreamSubscription s = formSubscriptions[path];
    if (s != null) {
      s.cancel();
      formSubscriptions.remove(path);
    }
    cache._clear(path);
  }

  @override
  void visit(String path) {
    assert(path != null);
    _elt = cache.get(path);
    _path = path;
    assert(_elt is HtmlElement);
  }

  @override
  void replaceElement(String html) {
    if (_elt == null) {
      cache.container.setInnerHtml(html, treeSanitizer: _sanitizer);
    } else {
      Element after = _newElement(html);
      _elt.replaceWith(after);
    }
  }

  @override
  void setAttribute(String key, String value) {
    _elt.setAttribute(key, value);
    // Setting the "value" attribute on an input element doesn't actually change what's in the text box.
    if (key == "value") {
      HtmlElement elt = _elt;
      if (elt is InputElement) {
        elt.value = value;
      } else if (elt is TextAreaElement) {
        elt.value = value;
      }
    }
  }

  @override
  void removeAttribute(String key) {
    _elt.attributes.remove(key);
  }

  @override
  void setInnerHtml(String html) {
    _elt.setInnerHtml(html, treeSanitizer: _sanitizer);
  }

  @override
  void setInnerText(String text) {
    _elt.text = text;
  }

  @override
  void addChildElement(String childHtml) {
    Element newElt = _newElement(childHtml);
    _elt.children.add(newElt);
  }

  @override
  void replaceChildElement(int index, String childHtml) {
    Element newElt = _newElement(childHtml);
    _elt.children[index].replaceWith(newElt);
  }

  @override
  void removeChild(int index) {
    _elt.childNodes[index].remove();
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
  bool allowsAttribute(Element elt, String att, String value) =>
      att == "data-path";
  bool allowsElement(Element elt) => false;
}
