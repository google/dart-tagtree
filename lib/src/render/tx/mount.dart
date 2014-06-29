part of render;

/// A Transaction mixin that implements mounting a view.
abstract class _Mount {

  // Dependencies
  _InvalidateFunc get invalidate;

  // What was mounted
  final List<_ElementNode> _renderedRefs = [];
  final List<_ElementNode> _mountedForms = [];
  void addRenderCallback(OnRendered callback);
  void addHandler(HandlerType type, String path, val);

  /// Recursively expands a view to find the underlying HTML elements to render.
  /// Appends the HTML to a buffer and returns a tree data structure corresponding to it.
  ///
  /// The path is a string starting with "/" and using "/" as a separator, for example
  /// "/asdf/1/2/3", chosen to ensure uniqueness in the DOM. An expanded node and its
  /// shadow(s) have the same path. An element's children have a path that's a suffix
  /// of the parent's path. When rendered to HTML, an element's path shows up in the
  /// data-path attribute.
  ///
  /// The depth is used to sort updates at render time. It's the depth in the
  /// view tree, not the depth in the DOM tree (like the path). An expanded node
  /// has a lower depth than its shadow.
  _Node mountView(View view, Theme theme, StringBuffer html, String path, int depth) {

    var anim = findAnimation(view, theme);
    if (anim is ElementType) {
      var node = new _ElementNode(path, depth, view);
      _expandElement(node, theme, html);
      return node;
    } else {
      var node = new _AnimatedNode(path, depth, view, anim, invalidate);
      var shadow = node.renderFrame(view);

      // Recurse.
      node.shadow = mountView(shadow, theme, html, node.path, node.depth + 1);

      // This is last so that the shadows' callbacks happen before the parent.
      addRenderCallback(node.onRendered);

      return node;
    }
  }

  /// Returns the animation to be used to display the given View.
  Animator findAnimation(View view, Theme theme) {
    assert(view.checked());

    if (theme != null) {
      CreateExpander create = theme[view.runtimeType];
      if (create != null) {
        Animator result = create();
        assert(result != null);
        return result;
      }
    }

    Animator animation = view.animator;
    if (animation == null) {
      if (theme == null) {
        throw "There is no animation for ${view.runtimeType} and no theme is installed";
      } else {
        throw "Theme ${theme.name} has no animation for ${runtimeType}";
      }
    }
    return animation;
  }

  /// Render an HTML element by recursively expanding its children.
  void _expandElement(_ElementNode elt, Theme theme, StringBuffer out) {
    var view = elt.view;

    _writeStartTag(out, elt);

    if (view.htmlTag == "textarea") {
      String val = elt.props["defaultValue"];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
      // TODO: other cases?
    } else {
      elt.children = expandInner(elt, theme, out, view.inner);
    }

    out.write("</${view.htmlTag}>");

    if (view.ref != null) {
      _renderedRefs.add(elt);
    }
    if (view.htmlTag == "form") {
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