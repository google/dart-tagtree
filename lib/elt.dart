part of viewlet;

/// A virtual DOM element.
class Elt extends View {
  final String name;
  Map<Symbol, dynamic> _props;

  Inner _inner; // non-null when mounted

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

    if (name == "form") {
      // onSubmit doesn't bubble correctly
      didMount = () {
        getDom().onSubmit.listen((Event e) {
          print("form submitted: ${path}");
          e.stopPropagation();
          dispatchEvent(e, #onSubmit);
        });
      };
    }
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
    _inner = new Inner(this);
    _inner.mount(out, _props[#inner]);
    out.write("</${name}>");
  }

  void unmount() {
    for (Symbol key in allHandlers.keys) {
      Map m = allHandlers[key];
      m.remove(path);
    }
    _inner.unmount();
    super.unmount();
    print("unmount: ${_path}");
  }

  bool canUpdateTo(View other) => (other is Elt) && other.name == name;

  void update(Elt nextVersion) {
    if (nextVersion == null) {
      print("no change to Elt ${name}: ${_path}");
      return; // no internal state to update
    }
    Map<Symbol, dynamic> oldProps = _props;
    _props = nextVersion._props;

    print("updating Elt ${name}: ${_path}");
    Element elt = getDom();
    _updateDomProperties(elt, oldProps);
    _inner.update(elt, _props[#inner]);
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
        print("removing property: ${name}");
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
        String val = _makeDomVal(key, newVal);
        print("setting property: ${name}='${val}'");
        elt.setAttribute(name, val);
        // Setting the "value" attribute on an input element doesn't actually change what's in the text box.
        if (name == "value" && elt is InputElement) {
          elt.value = newVal;
        }
      }
    }
  }
}

class Inner{
  final Elt _parent;
  // Non-null when the Elt is mounted and it has at least one child.
  List<View> _children = null;
  // Non-null when the Elt is mounted and it contains just text.
  String _childText = null;

  Inner(this._parent);

  void mount(StringBuffer out, inner) {
    if (inner == null) {
      // none
    } else if (inner is String) {
      out.write(HTML_ESCAPE.convert(inner));
      _childText = inner;
    } else if (inner is View) {
      _children = _mountChildren(out, [inner]);
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
      _children = _mountChildren(out, children);
    }
  }

  List<View> _mountChildren(StringBuffer out, List<View> children) {
    if (children.isEmpty) {
      return null;
    }

    for (int i = 0; i < children.length; i++) {
      children[i].mount(out, "${_parent.path}/${i}", _parent._depth + 1);
    }
    return children;
  }

  void unmount() {
    if (_children != null) {
      for (View child in _children) {
        child.unmount();
      }
      _children = null;
    }
  }

  /// Updates the inner DOM and mount/unmounts children when needed.
  /// (Postcondition: _children is updated.)
  void update(Element elt, newInner) {
    if (newInner == null) {
      unmount();
      elt.text = "";
    } else if (newInner is String) {
      if (newInner == _childText) {
        return;
      }
      unmount();
      print("setting text of ${_parent.path}");
      elt.text = newInner;
      _childText = newInner;
    } else if (newInner is View) {
      _updateChildren(elt, [newInner]);
    } else if (newInner is Iterable) {
      List<View> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(new Text(item));
        } else if (item is View) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      _updateChildren(elt, children);
    }
  }

  /// Updates the inner DOM and mounts/unmounts children when needed.
  /// (Postcondition: _children and _childText are updated.)
  void _updateChildren(Element elt, List<View> newChildren) {

    if (_children == null) {
      print("_children is null");
      StringBuffer out = new StringBuffer();
      mount(out, newChildren);
      _unsafeSetInnerHtml(elt, out.toString());
      _children = newChildren;
      _childText = null;
      return;
    }

    List<View> updatedChildren = [];
    // update or replace each child that's in both lists
    int endBoth = _children.length < newChildren.length ? _children.length : newChildren.length;
    for (int i = 0; i < endBoth; i++) {
      View before = _children[i];
      assert(before != null);
      View after = newChildren[i];
      assert(after != null);
      if (before.canUpdateTo(after)) {
        before.update(after);
        updatedChildren.add(before);
      } else {
        print("replacing ${_parent.path} child ${i} from ${before.runtimeType} to ${after.runtimeType}");
        Element oldElt = elt.childNodes[i];
        before.unmount();
        var out = new StringBuffer();
        after.mount(out, "${_parent.path}/${i}", _parent._depth + 1);
        Element newElt = _unsafeNewElement(out.toString());
        oldElt.replaceWith(newElt);
        updatedChildren.add(after);
      }
    }

    if (_children.length > newChildren.length) {
      print("removing extra children under ${_parent.path}");
      // trim to new size
      for (int i = _children.length - 1; i >= newChildren.length; i--) {
        elt.childNodes[i].remove();
      }
    } else if (_children.length < newChildren.length) {
      print("adding extra children under ${_parent.path}");
      // append  children
      for (int i = _children.length; i < newChildren.length; i++) {
        View after = newChildren[i];
        var out = new StringBuffer();
        after.mount(out, "${_parent.path}/${i}", _parent._depth + 1);
        Element newElt = _unsafeNewElement(out.toString());
        elt.childNodes.add(newElt);
        updatedChildren.add(after);
      }
    }
    _children = updatedChildren;
    _childText = null;
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