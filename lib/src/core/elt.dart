part of core;

/// A virtual DOM element.
class Elt extends View with _Inner {
  final String tagName;
  Map<Symbol, dynamic> _props;

  Elt(this.tagName, Map<Symbol, dynamic> props) : super(props[#ref]),
      _props = props {
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

  Map<Symbol,dynamic> get props => _props;

  void doMount(StringBuffer out) {
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
    if (tagName == "textarea") {
      String val = _props[#defaultValue];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
    } else {
      _mountInner(out, _props[#inner], _props[#innerHtml]);
    }
    out.write("</${tagName}>");
  }

  void traverse(Visitor callback) {
    callback(this);
    _traverseInner(callback);
  }

  void doUnmount(NextFrame frame) {
    _unmountInner(frame);
    for (Symbol key in _allHandlers.keys) {
      Map m = _allHandlers[key];
      m.remove(path);
    }
    print("unmount: ${_path}");
  }

  bool canUpdateTo(View other) => (other is Elt) && other.tagName == tagName;

  void update(Elt nextVersion, ViewTree tree, NextFrame frame) {
    if (nextVersion == null) {
      print("no change to Elt ${tagName}: ${_path}");
      return; // no internal state to update
    }
    Map<Symbol, dynamic> oldProps = _props;
    _props = nextVersion._props;

    print("updating Elt ${tagName}: ${_path}");
    _updateDomProperties(oldProps, frame);
    _updateInner(_path, _props[#inner], _props[#innerHtml], tree, frame);
  }

  /// Updates DOM attributes and event handlers.
  void _updateDomProperties(Map<Symbol, dynamic> oldProps, NextFrame frame) {
    frame.currentElement = _path;

    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (_props.containsKey(key)) {
        continue;
      }

      if (_allHandlers.containsKey(key)) {
        _allHandlers[key].remove(path);
      } else if(_allAtts.containsKey(key)) {
        print("removing property: ${tagName}");
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
  } else {
    return val;
  }
}