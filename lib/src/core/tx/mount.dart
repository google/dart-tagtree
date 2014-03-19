part of core;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  // Dependencies to mount
  WidgetEnv get widgetEnv;

  // What was mounted
  final List<Ref> _mountedRefs = [];
  final List<Elt> _mountedForms = [];
  final List<Widget> _mountedWidgets = [];
  void addHandler(Symbol key, String path, EventHandler val);

  /// Writes the view tree to HTML and assigns an id to each View.
  ///
  /// The path should be a string starting with "/" and using "/" as a separator,
  /// for example "/asdf/1/2/3", chosen to ensure uniqueness in the DOM. The path
  /// of a child View is created by appending a suffix starting with "/" to its
  /// parent. When rendered to HTML, the path will show up in the data-path
  /// attribute.
  ///
  /// The depth is used to sort updates at render time. It's the depth in the
  /// view tree, not the depth in the DOM tree (like the path). For example,
  /// the root of a Widget's shadow tree has the same path, but its depth is
  /// incremented.
  void mountView(View view, StringBuffer html, String path, int depth) {
    view._mount(path, depth);
    if (view is Text) {
      _mountText(view, html);
    } else if (view is Widget) {
      _mountWidget(view, html);
    } else if (view is Elt) {
      _mountElt(view, html);
    } else {
      throw "cannot mount view: ${view.runtimeType}";
    }
    if (view._ref != null) {
      view._ref._set(view);
      _mountedRefs.add(view._ref);
    }
  }

  void _mountText(Text text, StringBuffer html) {
    // need to surround with a span to support incremental updates to a child
    html.write("<span data-path=${text.path}>${HTML_ESCAPE.convert(text.value)}</span>");
  }

  void _mountWidget(Widget widget, StringBuffer html) {
    widget._widgetEnv = widgetEnv;
    widget._state = widget.firstState;
    _mountShadow(html, widget);
    if (widget._didMount.hasListener) {
      _mountedWidgets.add(widget);
    }
  }

  void _mountShadow(StringBuffer html, Widget owner) {
    View newShadow = owner.render();
    mountView(newShadow, html, owner.path, owner.depth + 1);
    owner._shadow = newShadow;
  }

  void _mountElt(Elt elt, StringBuffer html) {
    _writeStartTag(html, elt.tagName, elt.path, elt._props);

    if (elt.tagName == "textarea") {
      String val = elt._props[#defaultValue];
      if (val != null) {
        html.write(HTML_ESCAPE.convert(val));
      }
    } else {
      mountInner(elt, html, elt._props[#inner], elt._props[#innerHtml]);
    }

    html.write("</${elt.tagName}>");

    if (elt.tagName == "form") {
      _mountedForms.add(elt);
    }
  }

  void _writeStartTag(StringBuffer out, String tagName, String path, Map<Symbol, dynamic> _props) {
    out.write("<${tagName} data-path=\"${path}\"");
    for (Symbol key in _props.keys) {
      var val = _props[key];
      if (allHandlerKeys.contains(key)) {
        addHandler(key, path, val);
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

  void mountInner(_Inner elt, StringBuffer out, inner, String innerHtml) {
    if (inner == null) {
      if (innerHtml != null) {
        // Assumes we are using a sanitizer. (Otherwise it would be unsafe!)
        out.write(innerHtml);
      }
    } else if (inner is String) {
      out.write(HTML_ESCAPE.convert(inner));
      elt._childText = inner;
    } else if (inner is View) {
      elt._children = _mountChildren(out, elt.path, elt.depth, [inner]);
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
      elt._children = _mountChildren(out, elt.path, elt.depth, children);
    }
  }

  List<View> _mountChildren(StringBuffer out, String parentPath, int parentDepth, List<View> children) {
    if (children.isEmpty) {
      return null;
    }

    int childDepth = parentDepth + 1;
    for (int i = 0; i < children.length; i++) {
      mountView(children[i], out, "${parentPath}/${i}", childDepth);
    }
    return children;
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
  } else if (val is int) {
    return val.toString();
  } else {
    return val;
  }
}