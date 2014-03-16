part of core;

/// A virtual DOM element.
class Elt extends View with _Inner implements Jsonable {
  final String tagName;
  Map<Symbol, dynamic> _props;

  Elt(this.tagName, Map<Symbol, dynamic> props)
      : _props = props,
        super(props[#ref]) {

    for (Symbol key in props.keys) {
      if (!_allEltProps.contains(key)) {
        throw "property not supported: ${key}";
      }
    }
    var inner = _props[#inner];
    assert(inner == null || inner is String || inner is View || inner is Iterable);
    assert(inner == null || _props[#innerHtml] == null);
    assert(_props[#value] == null || _props[#defaultValue] == null);
  }

  String get jsonTag => tagName;

  Props get props => new Props(_props);

  void doMount(Transaction tx, StringBuffer out) {
    _writeStartTag(out);

    if (tagName == "textarea") {
      String val = _props[#defaultValue];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
    } else {
      _mountInner(tx, out, _props[#inner], _props[#innerHtml]);
    }

    _writeEndTag(out);

    if (tagName == "form") {
      tx._mountedForms.add(this);
    }
  }

  void _writeStartTag(StringBuffer out) {
    out.write("<${tagName} data-path=\"${path}\"");
    for (Symbol key in _props.keys) {
      var val = _props[key];
      if (_allHandlers.containsKey(key)) {
        _allHandlers[key][path] = val;
      } else if (_allAtts.containsKey(key)) {
        String name = _allAtts[key];
        String escaped = HTML_ESCAPE.convert(_makeDomVal(key, val));
        out.write(" ${name}=\"${escaped}\"");
      }
    }
    if (tagName == "input") {
      String val = _props[#defaultValue];
      if (val != null) {
        String escaped = HTML_ESCAPE.convert(val);
        out.write(" value=\"${escaped}\"");
      }
    }
    out.write(">");
  }

  void _writeEndTag(out) {
    out.write("</${tagName}>");
  }

  void traverse(Visitor callback) {
    _traverseInner(callback);
    callback(this);
  }

  void doUnmount(NextFrame frame) {
    _unmountInner(frame);
    for (Symbol key in _allHandlers.keys) {
      Map m = _allHandlers[key];
      m.remove(path);
    }
  }

  bool canUpdateTo(View other) => (other is Elt) && other.tagName == tagName;

  void update(Elt nextVersion, Transaction tx) {
    assert(_path != null);
    if (nextVersion == null) {
      return; // no internal state to update
    }
    Map<Symbol, dynamic> oldProps = _props;
    _props = nextVersion._props;

    _updateDomProperties(oldProps, tx.frame);
    _updateInner(_path, _props[#inner], _props[#innerHtml], tx);
  }

  /// Updates DOM attributes and event handlers.
  void _updateDomProperties(Map<Symbol, dynamic> oldProps, NextFrame frame) {
    frame.visit(_path);

    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (_props.containsKey(key)) {
        continue;
      }

      if (_allHandlers.containsKey(key)) {
        _allHandlers[key].remove(path);
      } else if (_allAtts.containsKey(key)) {
        frame.removeAttribute(_allAtts[key]);
      }
    }

    // Update any new or changed props
    for (Symbol key in _props.keys) {
      var oldVal = oldProps[key];
      var newVal = _props[key];
      if (oldVal == newVal) {
        continue;
      }

      if (_allHandlers.containsKey(key)) {
        _allHandlers[key][path] = newVal;
      } else if (_allAtts.containsKey(key)) {
        String name = _allAtts[key];
        String val = _makeDomVal(key, newVal);
        frame.setAttribute(name, val);
      }
    }
  }

  /// A ruleSet that can encode any Elt as JSON.
  static final JsonRuleSet rules = (){
    var rs = new JsonRuleSet();
    for (String tag in _allTags.values) {
      rs.add(new EltRule(tag));
    }
    return rs;
  }();
}

String _makeDomVal(Symbol key, val) {
  if (key == #clazz) {
    if (val is String) {
      return val;
    } else if (val is List) {
      return val.join(" ");
    } else {
      throw "bad argument for clazz: ${val}";
    }
  } else if (val is int) {
    return val.toString();
  } else {
    return val;
  }
}

/// Encodes an Elt as tagged JSON.
class EltRule extends JsonRule {
  static final Map<Symbol, String> _symbolToFieldName = _eltPropToField;
  static final Map<String, Symbol> _fieldNameToSymbol = _invertMap(_symbolToFieldName);

  EltRule(String tag) : super(tag);

  @override
  bool appliesTo(Jsonable instance) {
    return instance is Elt && instance.tagName == tag && !instance._mounted;
  }

  @override
  getState(Elt instance) {
    Map<Symbol, dynamic> props = instance.props._props;
    var state = {};
    for (Symbol sym in props.keys) {
      var field = _symbolToFieldName[sym];
      assert(field != null);
      state[field] = props[sym];
    }
    return state;
  }

  @override
  Elt create(Map<String, dynamic> state) {
    var props = <Symbol, dynamic>{};
    for (String field in state.keys) {
      var sym = _fieldNameToSymbol[field];
      assert(sym != null);
      props[sym] = state[field];
    }
    return new Elt(tag, props);
  }
}

Map _invertMap(Map m) {
  var result = {};
  m.forEach((k,v) => result[v] = k);
  assert(m.length == result.length);
  return result;
}
