/**
 * Glue code connecting the ViewTree core (which is browser-independent) to the dart:html library.
 */
library browser;

import 'package:viewtree/core.dart' as core;

import 'dart:async' show StreamSubscription;
import 'dart:html';
import 'dart:collection' show HashMap;

int _treeIdCounter = 0;

/// Returns the Root corresponding to the given CSS selectors, creating it if needed.
///
/// The selectors must point to a single container element of type HtmlElement.
core.Root root(String containerSelectors) {
  HtmlElement container = querySelectorAll(containerSelectors).single;
  var prev = _findRoot(container);
  if (prev != null) {
    return prev;
  }

  var root = new _BrowserRoot(new _ElementCache(container));
  _pathToRoot[root.path] = root;
  return root;
}

class _BrowserRoot extends core.Root {
  final _ElementCache eltCache;

  _BrowserRoot(_ElementCache eltCache) :
    this.eltCache = eltCache,
    super(_treeIdCounter++);

  @override
  void afterFirstMount() {
    _listenForEvents(this, eltCache.container);
  }

  @override
  void onRequestAnimationFrame(core.RenderFunc render) {
    window.animationFrame.then((t) {
      render(new _NextFrame(eltCache));
    });
  }
}

/// Mounts a stream of views deserialized from a websocket.
///
/// The CSS selectors point to the container element where the views will be displayed.
/// The ruleSet will be used to deserialize the stream. (Only tags defined in the ruleset
/// can be deserialized.)
mountWebSocket(String webSocketUrl, String selectors, {core.JsonRuleSet rules}) {
  if (rules == null) {
    rules = core.eltRules;
  }

  var $ = new core.Tags();

  showStatus(String message) {
    print(message);
    root(selectors).mount($.Div(inner: message));
  }

  bool opened = false;
  var ws = new WebSocket(webSocketUrl);

  void onEvent(core.HandleCall call) {
    String json = rules.encodeTree(call);
    ws.sendString(json);
  }

  ws.onError.listen((_) {
    if (!opened) {
      showStatus("Can't connect to ${webSocketUrl}");
    } else {
      showStatus("Websocket error");
    }
  });

  ws.onMessage.listen((MessageEvent e) {
    if (!opened) {
      print("websocked opened");
    }
    opened = true;
    core.Tag tag = rules.decodeTree(e.data);
    core.HandleFunc func = onEvent;
    root(selectors).mount(tag, handler: func);
  });

  ws.onClose.listen((CloseEvent e) {
    if (!opened) {
      showStatus("Can't connect to ${webSocketUrl} (closed)");
    } else {
      showStatus("Disconnected from ${webSocketUrl}");
    }
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

  handle(Event e, Symbol handlerKey) {
    String path = _getTargetPath(e.target);
    if (path == null) {
      return;
    }
    root.dispatchEvent(new core.ViewEvent(handlerKey, path));
  }

  container.onClick.listen((e) => handle(e, #onClick));
  container.onMouseDown.listen((e) => handle(e, #onMouseDown));
  container.onMouseOver.listen((e) => handle(e, #onMouseOver));
  container.onMouseUp.listen((e) => handle(e, #onMouseUp));
  container.onMouseOut.listen((e) => handle(e, #onMouseOut));

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
class _NextFrame implements core.NextFrame {

  final _ElementCache cache;
  final Map<String, StreamSubscription> formSubscriptions = {};

  _NextFrame(this.cache);

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
  void replaceElement(String path, String html) {
    Element after = _newElement(html);
    _visit(path).replaceWith(after);
    cache._set(path, after);
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
  bool allowsAttribute(Element elt, String att, String value) =>
      att == "data-path";
  bool allowsElement(Element elt) => false;
}
