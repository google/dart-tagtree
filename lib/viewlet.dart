library viewlet;

import 'dart:html';
import 'dart:convert';

// infrastructure

int idCounter = 0;
Map<String, View> idToTree = {};
Set<View> _dirtyViews = new Set();
List<LifecycleHandler> didMountQueue = [];

void mount(View tree, HtmlElement container) {
  StringBuffer out = new StringBuffer();
  String id = "/${idCounter}"; idCounter++;
  tree.mount(out, id, 0);
  _unsafeSetInnerHtml(container, out.toString());

  for (LifecycleHandler h in didMountQueue) {
    h();
  }
  didMountQueue.clear();

  container.onChange.listen((Event e) => dispatchEvent(e, #onChange));
  container.onClick.listen((Event e) => dispatchEvent(e, #onClick));
  container.onSubmit.listen((Event e) => dispatchEvent(e, #onSubmit));
  idToTree[id] = tree;
}

void dispatchEvent(Event e, Symbol handlerKey) {
  print("got event: ${e} with key ${handlerKey}");
  var target = e.target;
  if (target is Element) {
    // TODO: bubbling. For now, just exact match.
    String id = target.dataset["path"];
    EventHandler h = allHandlers[handlerKey][id];
    if (h != null) {
      print("dispatched");
      h(e);
      applyUpdates();
    }
  }
}

void applyUpdates() {
  List<View> batch = new List.from(_dirtyViews);
  _dirtyViews.clear();

  // Sort ancestors ahead of children.
  batch.sort((a, b) => a._depth - b._depth);
  for (View v in batch) {
    v.refresh(null);
  }

  // No new updates should be requested while refreshing.
  assert(_dirtyViews.isEmpty);
}

typedef EventHandler(e);

Map<Symbol, Map<String, EventHandler>> allHandlers = {
  #onChange: {},
  #onClick: {},
  #onSubmit: {}
};

typedef LifecycleHandler();

/// A View is a node in a view tree.
///
/// A View can can be an HTML Element ("Elt"), plain text ("Text"), or a Widget.
/// Each Widget generates a "shadow" view tree to represent it. To calculate the HTML
/// that will actually be displayed, recursively replace each Widget with its shadow,
/// resulting in a tree containing only Elt and Text nodes.
///
/// Conceptually, each View has a set of *props*, which are a generalization of HTML
/// attributes. Props are always passed in as arguments to a View constructor, but may
/// be copied from one View to another of the same type using an updateTo() call.
/// (Exactly how this happens depends on the view.)
///
/// In addition, some views may have internal state, which can change in response to
/// events. When a Widget changes state, its shadow must be re-rendered. When
/// re-rendering, we attempt to preserve as many View nodes as possible by updating them
/// in place. This is both more efficient and preserves state.
abstract class View {
  LifecycleHandler didMount, willUnmount;

  bool _mounted = false;
  String _path;
  int _depth;
  View _nextVersion;

  View();

  /// Returns a unique id used to find the view's HTML element.
  ///
  /// The path is set at mount time and never changes afterward.
  String get path => _path;

  /// Returns the view's current props (for debugging).
  Map<Symbol,dynamic> get props;

  /// Writes the view tree to HTML and assigns an id to each View.
  ///
  /// The path should be a string starting with "/" and using "/" as a separator,
  /// for example "/asdf/1/2/3", chosen to ensure uniqueness in the DOM.
  /// The path of a child View is created by appending a suffix starting with "/" to its
  /// parent. When rendered to HTML, the path will show up in the data-path attribute.
  ///
  /// A Widget has the same path as the root node in its shadow tree (recursively).
  void mount(StringBuffer out, String path, int depth) {
    _path = path;
    _depth = depth;
    _mounted = true;
    if (didMount != null) {
      didMountQueue.add(didMount);
    }
  }

  /// Frees resources associated with this View, not including any DOM nodes.
  void unmount() {
    if (willUnmount != null) {
      willUnmount();
    }
    _mounted = false;
  }

  /// Returns true if we can do an in-place update that sets the props to those of the given view.
  ///
  /// If so, we can call refresh(). Otherwise, we must unmount the view and mount its replacement,
  /// so all state will be lost.
  bool canUpdateTo(View nextVersion);

  /// Updates a view in place. After the update, it should have the same properties as nextVersion.
  /// If nextVersion is null, the props are unchanged, but a stateful view may apply any pending
  /// state.
  /// (This should only be called by the framework.)
  void refresh(View nextVersion);
}

/// A virtual DOM element.
class Elt extends View {
  final String name;
  Map<Symbol, dynamic> _props;
  List<View> _children; // non-null when Elt is mounted

  Elt(this.name, this._props) {
    for (Symbol key in props.keys) {
      var val = props[key];
      if (key == #inner || allAtts.containsKey(key) || allHandlers.containsKey(key)) {
        // ok
      } else {
        throw "property not supported: ${key}";
      }
    }
    var inner = _props[#inner];
    assert(inner == null || inner is String || inner is View || inner is Iterable);
  }

  Map<Symbol,dynamic> get props => _props;

  void mount(StringBuffer out, String path, int depth) {
    super.mount(out, path, depth);
    out.write("<${name} data-path=\"${path}\"");
    for (Symbol key in _props.keys) {
      var val = _props[key];
      if (allHandlers.containsKey(key)) {
        allHandlers[key][path] = val;
      } else if (allAtts.containsKey(key)) {
        String name = allAtts[key];
        String escaped = HTML_ESCAPE.convert(_makeDomVal(key, val));
        out.write(" ${name}=\"${escaped}\"");
      }
    }
    out.write(">");
    _mountInner(out, _props[#inner]);
    out.write("</${name}>");
  }

  void _mountInner(StringBuffer out, inner) {
    if (inner == null) {
      // none
    } else if (inner is String) {
      out.write(HTML_ESCAPE.convert(inner));
    } else if (inner is View) {
      _mountChildren(out, [inner]);
    } else if (inner is Iterable) {
      List<View> children = [];
      for (var item in inner) {
        if (item is String) {
          children.add(new Text(item));
        } else if (item is View) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      _mountChildren(out, children);
    }
  }

  void _mountChildren(StringBuffer out, List<View> children) {
    _children = children;
    for (int i = 0; i < children.length; i++) {
      children[i].mount(out, "${path}/${i}", _depth + 1);
    }
  }

  void unmount() {
    for (Symbol key in allHandlers.keys) {
      Map m = allHandlers[key];
      m.remove(path);
    }
    _unmountChildren();
    super.unmount();
  }

  void _unmountChildren() {
    if (_children != null) {
      for (View child in _children) {
        child.unmount();
      }
    }
  }

  bool canUpdateTo(View other) => (other is Elt) && other.name == name;

  void refresh(Elt nextVersion) {
    if (nextVersion == null) {
      return; // no internal state to update
    }
    Map<Symbol, dynamic> oldProps = _props;
    _props = nextVersion._props;

    Element elt = querySelector("[data-path=\"${_path}\"]");

    _updateDomProperties(elt, oldProps);

    // TODO: update children
    _unmountChildren();
    var buf = new StringBuffer();
    _mountInner(buf, _props[#inner]);
    _unsafeSetInnerHtml(elt, buf.toString());
  }

  /// Updates DOM attributes and event handlers.
  void _updateDomProperties(Element elt, Map<Symbol, dynamic> oldProps) {
    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (_props.containsKey(key)) {
        continue;
      }

      if (allHandlers.containsKey(key)) {
        allHandlers[key].remove(path);
      } else if(allAtts.containsKey(key)) {
        elt.attributes.remove(allAtts[key]);
      }
    }

    // Update any new or changed props
    for (Symbol key in _props.keys) {
      var oldVal = oldProps[key];
      var newVal = _props[key];
      if (oldVal == newVal) {
        continue;
      }

      if (allHandlers.containsKey(key)) {
        allHandlers[key][path] = newVal;
      } else if (allAtts.containsKey(key)) {
        String name = allAtts[key];
        elt.attributes[name] = _makeDomVal(key, newVal);
      }
    }
  }

  static String _makeDomVal(Symbol key, val) {
    if (key == #clazz) {
      if (val is String) {
        return val;
      } else if (val is List) {
        return val.join(" ");
      } else {
        throw "bad argument for clazz: ${val}";
      }
    } else {
      return val;
    }
  }
}

/// A plain text view.
///
/// The framework needs to find the corresponding DOM element using a query on a
/// data-path attribute, so the text is actually rendered inside a <span>.
/// (We can't support mixed-content HTML directly and instead use a list of Elt and
/// Text views as the closest equivalent.)
///
/// However, if the parent's "inner" property is just a string, it's handled as a
/// special case and the Text class isn't used.
class Text extends View {
  String value;
  Text(this.value);

  Map<Symbol,dynamic> get props => {#value: value};

  void mount(StringBuffer out, String path, int depth) {
    super.mount(out, path, depth);
    // need to surround with a span to support incremental updates to a child
    out.write("<span data-path=${path}>${HTML_ESCAPE.convert(value)}</span>");
  }

  void unmount() {}

  bool canUpdateTo(View other) => (other is Text);

  void refresh(Text nextVersion) {
    if (nextVersion == null || value == nextVersion.value) {
      return; // no internal state to update
    }
    value = nextVersion.value;
    Element elt = querySelector("[data-path=\"${_path}\"]");
    elt.text = value;
  }
}

/// A Widget is a View that acts as a template. Its render() method typically
/// returns elements to be rendered
abstract class Widget extends View {
  Map<Symbol, dynamic> _props;
  State _state, _nextState;
  View shadow;

  Widget(this._props);

  /// Constructs the initial state when the Widget is mounted.
  /// (Stateful widgets should override.)
  State get firstState => null;

  /// Returns the currently rendered state. This should be treated as read-only.
  /// (Subclasses may want to override to change the return type.)
  State get state => _state;

  /// Returns the state that will be rendered on the next update.
  /// This is typically used to update the state due to an event.
  /// Accessing nextState automatically marks the Widget as dirty.
  /// (Subclasses may want to override to change the return type.)
  State get nextState {
    if (_nextState == null) {
      _nextState = _state.clone();
      _dirtyViews.add(this);
    }
    return _nextState;
  }

  /// Sets the state to be rendered on the next update.
  /// Setting the nextState automatically marks the Widget as dirty.
  void set nextState(State s) {
    _nextState = s;
    _dirtyViews.add(this);
  }

  void mount(StringBuffer out, String path, int depth) {
    super.mount(out, path, depth);
    _state = firstState;
    shadow = render();
    shadow.mount(out, path, depth);
  }

  void unmount() {
    shadow.unmount();
    shadow = null;
  }

  /// Constructs another View to be rendered in place of this Widget.
  /// (This is somewhat similar to "shadow DOM".)
  View render();

  bool canUpdateTo(View other) => false;

  void refresh(Widget nextVersion) {
    assert(_mounted);

    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }

    Element before = querySelector("[data-path=\"${_path}\"]");

    shadow.unmount();
    shadow = render();
    StringBuffer out = new StringBuffer();
    shadow.mount(out, _path, _depth);
    Element after = _unsafeNewElement(out.toString());

    before.replaceWith(after);
  }

  Map<Symbol, dynamic> get props => _props;
}

/// The internal state of a stateful Widget.
/// (Each stateful Widget will typically have a corresponding subclass of State.)
abstract class State {
  /// Returns a copy of the state, to be rendered on the next refresh.
  State clone();
}

/// An API for constructing the corresponding view for each HTML Element.
/// (Typically Tags is used instead.)
abstract class TagsApi {
  View Div({clazz, onClick, inner});
  View Span({clazz, onClick, inner});

  View H1({clazz, onClick, inner});
  View H2({clazz, onClick, inner});
  View H3({clazz, onClick, inner});

  View Ul({clazz, onClick, inner});
  View Li({clazz, onClick, inner});

  View Form({clazz, onClick, onSubmit, inner});
  View Input({clazz, onClick, onChange, value, inner});
  View Button({clazz, onClick, inner});
}

Map<Symbol, String> allTags = {
  #Div: "div",
  #Span: "span",

  #H1: "h1",
  #H2: "h2",
  #H3: "h3",

  #Ul: "ul",
  #Li: "li",

  #Form: "form",
  #Input: "input",
  #Button: "button"
};

Map<Symbol, String> allAtts = {
  #clazz: "class",
  #value: "value"
};

/// A factory for constructing the corresponding view for each HTML Element.
/// (Typically assigned to '$'.)
class Tags implements TagsApi {
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      String tag = allTags[inv.memberName];
      if (tag != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "position arguments not supported for html tags";
        }
        return new Elt(tag, inv.namedArguments);
      }
    }
    throw new NoSuchMethodError(this,
        inv.memberName, inv.positionalArguments, inv.namedArguments);
  }
}

Element _unsafeNewElement(String html) {
  return new Element.html(html, treeSanitizer: _NullSanitizer.instance);
}

void _unsafeSetInnerHtml(HtmlElement elt, String html) {
  elt.setInnerHtml(html, treeSanitizer: _NullSanitizer.instance);
}

class _NullSanitizer implements NodeTreeSanitizer {
  static var instance = new _NullSanitizer();
  void sanitizeTree(Node node) {}
}
