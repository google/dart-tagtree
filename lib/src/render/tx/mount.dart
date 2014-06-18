part of render;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  // Dependencies
  _Node makeNode(String path, int depth, View view, Theme theme);
  void invalidate(_ExpandedNode node);

  // What was mounted
  final List<_Node> _mountedRefs = [];
  final List<_ElementNode> _mountedForms = [];
  final List<OnRendered> _mountedExpanders = [];
  void addHandler(HandlerType type, String path, val);

  /// Expands templates and starts widgets for each view in a tag tree.
  /// Appends the HTML to a buffer and returns the corresponding node tree.
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
  _Node mountView(View view, Theme theme, StringBuffer html, String path, int depth) {
    _Node node = makeNode(path, depth, view, theme);
    _expandNode(node, theme, html, path, depth);
    if (node.view.ref != null) {
      _mountedRefs.add(node);
    }
    return node;
  }

  void _expandNode(_Node node, Theme theme, StringBuffer out, String path, int depth) {
    var view = node.view;

    if (node is _ExpandedNode) {
      var expander = node.expander;
      if (expander is Widget) {
        expander.mount(view, () => invalidate(node));
      }

      View shadow = expander.expand(view);

      node.shadow = mountView(shadow, theme, out, path, depth + 1);
      if (expander.onRendered != null) {
        _mountedExpanders.add(expander.onRendered);
      }

    } else if (node is _ElementNode) {
      _expandElement(node, theme, out);
    } else {
      throw "unknown node type";
    }
  }

  _cast(x) => x;

  /// Expands the descendants of an element node and renders the result to HTML.
  void _expandElement(_ElementNode elt, Theme theme, StringBuffer out) {
    _writeStartTag(out, elt);

    if (elt.view.htmlTag == "textarea") {
      String val = elt.props["defaultValue"];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
      // TODO: other cases?
    } else {
      elt.children = expandInner(elt, theme, out, elt.view.inner);
    }

    out.write("</${elt.view.htmlTag}>");

    if (elt.view.htmlTag == "form") {
      _mountedForms.add(elt);
    }
  }

  void _writeStartTag(StringBuffer out, _ElementNode elt) {
    out.write("<${elt.view.htmlTag} data-path=\"${elt.path}\"");
    ElementType eltType = elt.view.type;
    for (String key in elt.view.props.keys) {
      var propType = eltType.propsByName[key];
      var val = elt.props[key];
      if (propType is HandlerType) {
        addHandler(propType, elt.path, val);
        continue;
      } else if (propType is AttributeType) {
        String escaped = HTML_ESCAPE.convert(_makeDomVal(key, val));
        out.write(" ${propType.propKey}=\"${escaped}\"");
      }
    }
    if (elt.view.htmlTag == "input") {
      String val = elt.props["defaultValue"];
      if (val != null) {
        String escaped = HTML_ESCAPE.convert(val);
        out.write(" value=\"${escaped}\"");
      }
    }
    out.write(">");
  }

  /// Returns the new children
  dynamic expandInner(_ElementNode elt, Theme theme, StringBuffer out, inner) {
    if (inner == null) {
      return null;
    } else if (inner is String) {
      out.write(HTML_ESCAPE.convert(inner));
      return inner;
    } else if (inner is RawHtml) {
      // Assumes we are using a sanitizer. (Otherwise it would be unsafe!)
      out.write(inner.html);
      return inner;
    } else if (inner is View) {
      return _mountChildren(out, elt.path, elt.depth, [inner], theme);
    } else if (inner is Iterable) {
      List<View> children = [];
      for (var item in inner) {
        if (item is String) {
          children.add(_textType.makeView({"inner": item}));
        } else if (item is View) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      return _mountChildren(out, elt.path, elt.depth, children, theme);
    }
    throw "unexpected type for an element's inner field: ${inner.runtimeType}";
  }

  List<_Node> _mountChildren(StringBuffer out, String parentPath, int parentDepth,
      List<View> children, Theme theme) {
    if (children.isEmpty) {
      return null;
    }

    int childDepth = parentDepth + 1;
    var result = <_Node>[];
    for (int i = 0; i < children.length; i++) {
      result.add(mountView(children[i], theme, out, "${parentPath}/${i}", childDepth));
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