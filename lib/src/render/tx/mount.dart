part of render;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  // Dependencies
  _InvalidateWidgetFunc get invalidateWidget;

  // What was mounted
  final List<_View> _mountedRefs = [];
  final List<_Elt> _mountedForms = [];
  final List<EventSink> _mountedWidgets = [];
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
  _View mountView(TagNode tag, StringBuffer html, String path, int depth) {
    _View view = _mountTag(tag, html, path, depth);
    if (view.ref != null) {
      _mountedRefs.add(view);
    }
    return view;
  }

  _View _mountTag(TagNode tag, StringBuffer out, String path, int depth) {
    TagDef def = tag.def;

    if (def is _TextDef) {
      _Text text = new _Text(path, depth, tag.props[#value]);
      // need to surround with a span to support incremental updates to a child
      out.write("<span data-path=${text.path}>${HTML_ESCAPE.convert(text.value)}</span>");
      return text;

    } else if (def is TemplateDef) {
      _Template view = new _Template(def, path, depth, tag.propMap);
      TagNode shadow = def.render(tag.propMap);
      view.shadow = mountView(shadow, out, path, depth + 1);
      view.props = tag.props;
      return view;

    } else if (def is WidgetDef) {
      var w = def.make();
      var v = new _Widget(def, path, depth, tag[#ref]);
      var c = w.mount(tag.propMap, () => invalidateWidget(v));
      v.controller = c;

      TagNode newShadow = w.render();
      v.shadow = mountView(newShadow, out, v.path, v.depth + 1);

      if (c.didMount.hasListener) {
        _mountedWidgets.add(c.didMount);
      }

      return v;

    } else if (def is EltDef) {
      _Elt elt = new _Elt(def, path, depth, tag.propMap);
      _mountElt(elt, out);
      return elt;

    } else {
      throw "can't mount tag: ${tag.runtimeType}";
    }
  }

  void _mountElt(_Elt elt, StringBuffer out) {
    _writeStartTag(out, elt.def, elt.path, elt.props);

    if (elt.tagName == "textarea") {
      String val = elt.props[#defaultValue];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
    } else {
      mountInner(elt, out, elt.props[#inner], elt.props[#innerHtml]);
    }

    out.write("</${elt.tagName}>");

    if (elt.tagName == "form") {
      _mountedForms.add(elt);
    }
  }

  void _writeStartTag(StringBuffer out, EltDef def, String path, Map<Symbol, dynamic> _props) {
    out.write("<${def.tagName} data-path=\"${path}\"");
    for (Symbol key in _props.keys) {
      var val = _props[key];
      if (def.isHandler(key)) {
        addHandler(key, path, val);
        continue;
      }
      String att = def.getAttributeName(key);
      if (att != null) {
        String escaped = HTML_ESCAPE.convert(_makeDomVal(key, val));
        out.write(" ${att}=\"${escaped}\"");
      }
    }
    if (def.tagName == "input") {
      String val = _props[#defaultValue];
      if (val != null) {
        String escaped = HTML_ESCAPE.convert(val);
        out.write(" value=\"${escaped}\"");
      }
    }
    out.write(">");
  }

  void mountInner(_Elt elt, StringBuffer out, inner, String innerHtml) {


    if (inner == null) {
      if (innerHtml != null) {
        // Assumes we are using a sanitizer. (Otherwise it would be unsafe!)
        out.write(innerHtml);
      }
    } else if (inner is String) {
      out.write(HTML_ESCAPE.convert(inner));
      elt._childText = inner;
    } else if (inner is TagNode) {
      elt._children = _mountChildren(out, elt.path, elt.depth, [inner]);
    } else if (inner is Iterable) {
      List<TagNode> children = [];
      for (var item in inner) {
        if (item is String) {
          children.add(_TextDef.instance.makeTag({#value: item}));
        } else if (item is TagNode) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      elt._children = _mountChildren(out, elt.path, elt.depth, children);
    }
  }

  List<_View> _mountChildren(StringBuffer out, String parentPath, int parentDepth,
      List<TagNode> children) {
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