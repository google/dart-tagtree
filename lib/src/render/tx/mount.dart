part of render;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  // Dependencies
  _MakeViewFunc makeView;
  _InvalidateWidgetFunc get invalidateWidget;

  // What was mounted
  final List<_View> _mountedRefs = [];
  final List<_EltView> _mountedForms = [];
  final List<EventSink> _mountedWidgets = [];
  void addHandler(HandlerType type, String path, val);

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
  _View mountView(TaggedNode node, StringBuffer html, String path, int depth) {
    _View view = _mountTag(node, html, path, depth);
    if (view.node.ref != null) {
      _mountedRefs.add(view);
    }
    return view;
  }

  _View _mountTag(TaggedNode node, StringBuffer out, String path, int depth) {
    _View view = makeView(path, depth, node);
    if (view is _TextView) {
      // need to surround with a span to support incremental updates to a child
      out.write("<span data-path=${view.path}>${HTML_ESCAPE.convert(view.node.value)}</span>");
      return view;

    } else if (view is _TemplateView) {
      TaggedNode shadowNode = view.render(node);
      view.shadow = mountView(shadowNode, out, path, depth + 1);
      return view;

    } else if (view is _WidgetView) {
      var widget = view.createWidget();
      var c = widget.mount(node, () => invalidateWidget(view));
      view.controller = c;

      TaggedNode shadowNode = widget.render();
      view.shadow = mountView(shadowNode, out, view.path, view.depth + 1);

      if (c.didMount.hasListener) {
        _mountedWidgets.add(c.didMount);
      }

      return view;

    } else if (view is _EltView) {
      _mountElt(view, out);
      return view;

    } else {
      throw "can't mount node for unknown tag type: ${view.runtimeType}";
    }
  }

  void _mountElt(_EltView elt, StringBuffer out) {
    _writeStartTag(out, elt);

    if (elt.node.tag == "textarea") {
      String val = elt.node["defaultValue"];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
    } else {
      mountInner(elt, out, elt.node["inner"], elt.node["innerHtml"]);
    }

    out.write("</${elt.node.tag}>");

    if (elt.node.tag == "form") {
      _mountedForms.add(elt);
    }
  }

  void _writeStartTag(StringBuffer out, _EltView elt) {
    out.write("<${elt.node.tag} data-path=\"${elt.path}\"");
    for (String key in elt.node.keys) {
      var type = elt.type.propsByName[key];
      var val = elt.node[key];
      if (type is HandlerType) {
        addHandler(type, elt.path, val);
        continue;
      } else if (type is AttributeType) {
        String escaped = HTML_ESCAPE.convert(_makeDomVal(key, val));
        out.write(" ${type.name}=\"${escaped}\"");
      }
    }
    if (elt.node.tag == "input") {
      String val = elt.node["defaultValue"];
      if (val != null) {
        String escaped = HTML_ESCAPE.convert(val);
        out.write(" value=\"${escaped}\"");
      }
    }
    out.write(">");
  }

  void mountInner(_EltView elt, StringBuffer out, inner, String innerHtml) {

    if (inner == null) {
      if (innerHtml != null) {
        // Assumes we are using a sanitizer. (Otherwise it would be unsafe!)
        out.write(innerHtml);
      }
    } else if (inner is String) {
      out.write(HTML_ESCAPE.convert(inner));
      elt._childText = inner;
    } else if (inner is TaggedNode) {
      elt._children = _mountChildren(out, elt.path, elt.depth, [inner]);
    } else if (inner is Iterable) {
      List<TaggedNode> children = [];
      for (var item in inner) {
        if (item is String) {
          children.add(new _TextNode(item));
        } else if (item is TaggedNode) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      elt._children = _mountChildren(out, elt.path, elt.depth, children);
    }
  }

  List<_View> _mountChildren(StringBuffer out, String parentPath, int parentDepth,
      List<ElementNode> children) {
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

String _makeDomVal(String key, val) {
  if (key == "class") {
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