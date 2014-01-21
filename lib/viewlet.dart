library viewlet;

import 'dart:html';
import 'dart:convert';

// infrastructure

int idCounter = 0;
Map<String, View> idToTree = {};
Set<Widget> updated = new Set();

void mount(View tree, HtmlElement container) {
  StringBuffer out = new StringBuffer();
  String id = "/${idCounter}"; idCounter++;
  tree.mount(out, id, 0);
  _unsafeSetInnerHtml(container, out.toString());
  container.onClick.listen((MouseEvent e) {
    var target = e.target;
    if (target is Element) {
      // TODO: bubbling. For now, just exact match.
      String id = target.dataset["path"];
      Handler h = allHandlers[#onClick][id];
      if (h != null) {
        h(e);
        for (Widget w in updated) {
          w.refresh();
        }
      }
    }
  });
  idToTree[id] = tree;
}

Map<Symbol, String> allTags = {
  #Div: "div",
  #Span: "span"
};

typedef Handler(e);

Map<Symbol, Map<String, Handler>> allHandlers = {
  #onClick: {}
};

abstract class View {
  String _id;
  int _depth;
  View();

  void mount(StringBuffer out, String id, int depth) {
    _id = id;
    _depth = depth;
  }

  Map<Symbol,dynamic> get props;
}

class Elt extends View {
  final String name;
  final Map<Symbol, dynamic> _props;
  final inner;
  Elt(this.name, this._props, inner) : inner = _makeInner(inner);

  factory Elt.from(String name, Map<Symbol, dynamic> props) {
    var children;
    for (Symbol key in props.keys) {
      var val = props[key];
      if (key == #inner) {
        children = val;
      } else if (key == #clazz) {
        // ok
      } else if (allHandlers.containsKey(key)) {
        // It's an event handler.
      } else {
        throw "property not supported: ${key}";
      }
    }
    return new Elt(name, props, children);
  }

  void mount(StringBuffer out, String id, int depth) {
    super.mount(out, id, depth);
    out.write("<${name} data-path=\"${id}\"");
    for (Symbol key in _props.keys) {
      var val = _props[key];
      if (allHandlers.containsKey(key)) {
        allHandlers[key][id] = val;
      } else if (key == #clazz) {
        String escaped = HTML_ESCAPE.convert(_makeClassAttr(val));
        out.write(" class=\"${escaped}\"");
      }
    }
    out.write(">");
    if (inner == null) {
      // none
    } else if (inner is String) {
      out.write(HTML_ESCAPE.convert(inner));
    } else if (inner is List) {
      for (int i = 0; i < inner.length; i++) {
        inner[i].mount(out, "${id}/${i}", depth + 1);
      }
    } else {
      throw "bad argument to inner: ${inner}";
    }
    out.write("</${name}>");
  }

  Map<Symbol,dynamic> get props => _props;

  static _makeInner(inner) {
    if (inner == null || inner is String) {
      // special cases
      return inner;
    } else if (inner is View) {
      return [inner];
    } else if (inner is List) {
      // Handle mixed content
      List<View> result = [];
      for (var item in inner) {
        if (item is String) {
          result.add(new Text(item));
        } else if (item is View) {
          result.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      return result;
    }
    throw "bad argument to inner: ${inner}";
  }

  static String _makeClassAttr(val) {
    if (val is String) {
      return val;
    } else if (val is List) {
      return val.join(" ");
    } else {
      throw "bad argument for clazz: ${val}";
    }
  }
}

/// Some text that appears as a root or as a child in a list of Html nodes
/// (mixed content). If an Html node has text as its only child, it's handled
/// as a special case.
class Text extends View {
  final String value;
  Text(this.value);

  void mount(StringBuffer out, String id, int depth) {
    super.mount(out, id, depth);
    // need to surround with a span to support incremental updates to a child
    out.write("<span data-path=${id}>${HTML_ESCAPE.convert(value)}</span>");
  }

  Map<Symbol,dynamic> get props => {#value: value};
}

abstract class Widget extends View {
  Map<Symbol, dynamic> _props;
  dynamic _state, _nextState;
  View shadow;

  Widget(this._props);

  get firstState => null;

  get state => _state;

  set nextState(s) {
    _nextState = s;
  }

  void setState(Map updates) {
    if (_nextState == null) {
      _nextState = new Map.from(_state);
    }
    _nextState.addAll(updates);
    updated.add(this);
  }

  void mount(StringBuffer out, String id, int depth) {
    super.mount(out, id, depth);
    _state = firstState;
    shadow = render();
    shadow.mount(out, id, depth);
  }

  View render();

  void refresh() {
    assert(_id != null);

    if (_nextState != null) {
      _state = _nextState;
      _nextState = null;
    }

    Element before = querySelector("[data-path=\"${_id}\"]");

    StringBuffer out = new StringBuffer();
    shadow = render();
    shadow.mount(out, _id, _depth);
    Element after = _unsafeNewElement(out.toString());

    before.replaceWith(after);
  }

  Map<Symbol, dynamic> get props => _props;
}

abstract class TagsApi {
  View Div({clazz, onClick, inner});
  View Span({clazz, onClick, inner});
}

class Tags implements TagsApi {
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      String tag = allTags[inv.memberName];
      if (tag != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "position arguments not supported for html tags";
        }
        return new Elt.from(tag, inv.namedArguments);
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
