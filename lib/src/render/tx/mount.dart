part of render;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  // Dependencies
  Map<String, Renderer> get renderers;
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
    if (view.ref != null) {
      _mountedRefs.add(view);
    }
    return view;
  }

  _View _mountTag(TaggedNode node, StringBuffer out, String path, int depth) {
    Renderer r = renderers[node.tag];
    _View view;
    if (r != null) {
      view = renderers[node.tag]._makeView(node, path, depth);
    } else if (node is ElementNode && node.eltTag is ElementTag) {
      view = new _EltView(node, path, depth);
    } else {
      throw "can't determine renderer for node: {node.runtimeType}";
    }

    if (view is _TextView) {
      // need to surround with a span to support incremental updates to a child
      _TextView v = view;
      out.write("<span data-path=${v.path}>${HTML_ESCAPE.convert(v.node.value)}</span>");
      return view;

    } else if (view is _TemplateView) {
      _TemplateView v = view;
      TaggedNode shadow = v.renderer.render(node);
      v.shadow = mountView(shadow, out, path, depth + 1);
      return view;

    } else if (view is _WidgetView) {
      _WidgetView v = view;
      var widget = v.renderer.createWidget();
      var c = widget.mount(node, () => invalidateWidget(view));
      v.controller = c;

      TaggedNode newShadow = widget.render();
      v.shadow = mountView(newShadow, out, view.path, view.depth + 1);

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

    if (elt.tagName == "textarea") {
      String val = elt.node["defaultValue"];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
    } else {
      mountInner(elt, out, elt.node["inner"], elt.node["innerHtml"]);
    }

    out.write("</${elt.tagName}>");

    if (elt.tagName == "form") {
      _mountedForms.add(elt);
    }
  }

  void _writeStartTag(StringBuffer out, _EltView elt) {
    out.write("<${elt.tagName} data-path=\"${elt.path}\"");
    for (String key in elt.node.keys) {
      var type = elt.eltTag.getPropType(key);
      var val = elt.node[key];
      if (type is HandlerType) {
        addHandler(type, elt.path, val);
        continue;
      } else if (type is AttributeType) {
        String escaped = HTML_ESCAPE.convert(_makeDomVal(key, val));
        out.write(" ${type.name}=\"${escaped}\"");
      }
    }
    if (elt.tagName == "input") {
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