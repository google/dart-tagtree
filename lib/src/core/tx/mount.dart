part of core;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  // Dependencies to mount
  _InvalidateWidgetFunc get invalidateWidget;

  // What was mounted
  final List<_View> _mountedRefs = [];
  final List<_Elt> _mountedForms = [];
  final List<Widget> _mountedWidgets = [];
  void addHandler(Symbol key, String path, val);

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
  _View mountView(Tag tag, StringBuffer html, String path, int depth) {
    _View view = _mountTag(tag, html, path, depth);
    if (view.ref != null) {
      _mountedRefs.add(view);
    }
    return view;
  }

  _View _mountTag(Tag tag, StringBuffer html, String path, int depth) {
    TagDef def = tag.def;
    if (def is _TextDef) {
      _Text text = new _Text(path, depth, tag.props[#value]);
      // need to surround with a span to support incremental updates to a child
      html.write("<span data-path=${text.path}>${HTML_ESCAPE.convert(text.value)}</span>");
      return text;
    } else if (def is TemplateDef) {
      _Template view = new _Template(def, path, depth, tag.props);
      Tag shadow = def._render(tag.props);
      view.shadow = mountView(shadow, html, path, depth + 1);
      view.props = new Props(tag.props);
      return view;
    } else if (def is _WidgetDef) {
      _Widget view = new _Widget(tag, path, depth, invalidateWidget);
      _mountWidget(view, html);
      return view;
    } else if (def is EltDef) {
      _Elt elt = new _Elt(def, path, depth, tag.props);
      _mountElt(elt, html);
      return elt;
    } else {
      throw "can't mount tag: ${tag.runtimeType}";
    }
  }

  void _mountWidget(_Widget view, StringBuffer html) {
    Widget w = view.widget;
    Tag newShadow = w.render();
    view.shadow = mountView(newShadow, html, view.path, view.depth + 1);
    if (w._didMount.hasListener) {
      _mountedWidgets.add(w);
    }
  }

  void _mountElt(_Elt elt, StringBuffer html) {
    _writeStartTag(html, elt.tagName, elt.path, elt.props);

    if (elt.tagName == "textarea") {
      String val = elt.props[#defaultValue];
      if (val != null) {
        html.write(HTML_ESCAPE.convert(val));
      }
    } else {
      mountInner(elt, html, elt.props[#inner], elt.props[#innerHtml]);
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
      if (_htmlHandlerNames.containsKey(key)) {
        addHandler(key, path, val);
      } else if (_htmlAtts.containsKey(key)) {
        String name = _htmlAtts[key];
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
    } else if (inner is Tag) {
      elt._children = _mountChildren(out, elt.path, elt.depth, [inner]);
    } else if (inner is Iterable) {
      List<Tag> children = [];
      for (var item in inner) {
        if (item is String) {
          children.add(_TextDef.instance.makeTag(value: item));
        } else if (item is Tag) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      elt._children = _mountChildren(out, elt.path, elt.depth, children);
    }
  }

  List<_View> _mountChildren(StringBuffer out, String parentPath, int parentDepth, List<Tag> children) {
    if (children.isEmpty) {
      return null;
    }

    int childDepth = parentDepth + 1;
    var result = <_View>[];
    for (int i = 0; i < children.length; i++) {
      result.add(mountView(children[i], out, "${parentPath}/${i}", childDepth));
    }
    return result;
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