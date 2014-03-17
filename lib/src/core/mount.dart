part of core;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  Root get root;
  EventDispatcher get dispatcher;
  NextFrame get frame;

  // What was done
  final List<Ref> _mountedRefs = [];
  final List<Elt> _mountedForms = [];
  final List<Widget> _mountedWidgets = [];

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
    widget._root = root;
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

  void mountReplacementShadow(Widget owner, View newShadow) {
    // TODO: no longer need to visit early
    String path = owner.path;
    frame.visit(path);
    owner._shadow.unmount(this);

    var html = new StringBuffer();
    mountView(newShadow, html, path, owner.depth + 1);
    frame.replaceElement(html.toString());
  }

  void _mountElt(Elt elt, StringBuffer html) {
    _writeStartTag(html, elt.tagName, elt.path, elt._props);

    if (elt.tagName == "textarea") {
      String val = elt._props[#defaultValue];
      if (val != null) {
        html.write(HTML_ESCAPE.convert(val));
      }
    } else {
      elt._mountInner(this, html, elt._props[#inner], elt._props[#innerHtml]);
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
      if (dispatcher.isHandlerKey(key)) {
        dispatcher.setHandler(key, path, val);
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

  List<View> mountChildren(StringBuffer out, String parentPath, int parentDepth, List<View> children) {
    if (children.isEmpty) {
      return null;
    }

    int childDepth = parentDepth + 1;
    for (int i = 0; i < children.length; i++) {
      mountView(children[i], out, "${parentPath}/${i}", childDepth);
    }
    return children;
  }

  void mountNewChild(_Inner parent, View child, int childIndex) {
    var html = new StringBuffer();
    mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
      ..visit(parent.path)
      ..addChildElement(html.toString());
  }

  void mountReplacementChild(_Inner parent, View child, int childIndex) {
    StringBuffer html = new StringBuffer();
    mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
        ..visit(parent.path)
        ..replaceChildElement(childIndex, html.toString());
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