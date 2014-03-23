/**
 * Glue code connecting the ViewTree core (which is browser-independent) to the dart:html library.
 */
library browser;

import 'package:viewtree/core.dart' as core;

import 'dart:async' show StreamSubscription;
import 'dart:html';
import 'dart:collection' show HashMap;

int _treeIdCounter = 0;

/// Schedules the view to be mounted during the next rendered frame.
///
/// The CSS selectors must point to a single container element of type HtmlElement.
///
/// If the container element already contains a View, it will be replaced.
void mount(core.View view, String containerSelectors) {
  HtmlElement container = querySelectorAll(containerSelectors).single;
  var prev = _findRoot(container);
  if (prev != null) {
    prev.requestMount(view);
    return;
  }
  _ElementCache cache = new _ElementCache(container);
  int id = _treeIdCounter++;
  core.Root root = new core.Root(id, new _BrowserEnv(cache));
  _pathToRoot[root.path] = root;
  root.requestMount(view);
  _listenForEvents(root, container);
}

/// Mounts a stream of views deserialized from a websocket.
///
/// The CSS selectors point to the container element where the views will be displayed.
/// The ruleSet will be used to deserialize the stream. (Only tags defined in the ruleset
/// can be deserialized.)
void mountWebSocket(String webSocketUrl, String selectors, {core.JsonRuleSet rules}) {
  if (rules == null) {
    rules = core.Elt.rules;
  }
  var ws = new WebSocket(webSocketUrl);
  ws.onMessage.listen((MessageEvent e) {
    print("\nrendering view from socket");
    core.View view = rules.decodeTree(e.data);
    mount(view, "#view");
  });
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

Map<String, core.Root> _pathToRoot = {};

core.Root _findRoot(HtmlElement container) {
  var first = container.firstChild;
  if (first == null) {
    return null;
  }
  if (first is Element) {
    String path = first.getAttribute("data-path");
    if (path != null) {
      return _pathToRoot[path];
    }
  }
  return null;
}

void _listenForEvents(core.Root root, HtmlElement container) {

  container.onClick.listen((Event e) {
    String path = _getTargetPath(e.target);
    if (path == null) {
      return;
    }
    root.dispatchEvent(new core.ViewEvent(#onClick, path));
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
    root.dispatchEvent(new core.ChangeEvent(path, value));
  });

  // TODO: implement many more events.
  // TODO: remove handlers on unmount.
}

class _BrowserEnv implements core.RootEnv {
  final _ElementCache cache;

  _BrowserEnv(this.cache);

  @override
  void requestAnimationFrame(core.RenderFunction render) {
    window.animationFrame.then((t) {
      render(new _SyncFrame(cache));
    });
  }
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

  void _set(String path, HtmlElement elt) {
    pathToNode[path] = elt;
  }

  void _clear(String path) {
    pathToNode.remove(path);
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
  void onRefMounted(core.Ref ref) {
    if (ref is ElementRef) {
      ref.cache = cache;
    }
  }

  @override
  void onFormMounted(core.Root root, String formPath) {
    // onSubmit doesn't bubble, so install it here.
    FormElement elt = cache.get(formPath);
    formSubscriptions[formPath] = elt.onSubmit.listen((Event e) {
      String path = _getTargetPath(e.target);
      if (path != null) {
        e.preventDefault();
        e.stopPropagation();
        root.dispatchEvent(new core.ViewEvent(#onSubmit, path));
      }
    });
  }

  @override
  void onFormUnmounted(String formPath) {

  }

  @override
  void detachElement(String path, {bool willReplace: false}) {
    StreamSubscription s = formSubscriptions[path];
    if (s != null) {
      s.cancel();
      formSubscriptions.remove(path);
    }
    if (!willReplace) {
      cache._clear(path);
    }
  }

  @override
  void visit(String path) {
    assert(path != null);
    _elt = cache.get(path);
    _path = path;
    assert(_elt is HtmlElement);
  }

  @override
  void replaceElement(String path, String html) {
    visit(path);
    Element after = _newElement(html);
    _elt.replaceWith(after);
    cache._set(path, after);
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
