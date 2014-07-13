part of render;

/// A Transaction mixin that implements mounting a Tag.
abstract class _Mount {

  // Dependencies
  _InvalidateFunc get invalidate;

  // What was mounted
  final List<_ElementNode> _renderedRefs = [];
  final List<_ElementNode> _mountedForms = [];
  void addRenderCallback(Function callback);
  void addHandler(String typeName, String path, val);

  /// Recursively expands a [Tag] to find the underlying HTML elements to render.
  /// Appends the HTML to a buffer and returns a tree of nodes corresponding to it.
  ///
  /// The path is a string starting with "/" and using "/" as a separator, for example
  /// "/asdf/1/2/3", chosen to ensure uniqueness in the DOM. An animated node and its
  /// shadow(s) have the same path. An element's children have a path that's a suffix
  /// of the parent's path. When rendered to HTML, an element's path shows up in the
  /// data-path attribute.
  ///
  /// The depth is used to sort updates at render time. It's the depth in the
  /// tag tree, not the depth in the DOM tree (like the path). An animated node
  /// has a lower depth than its shadow tree.
  _Node mountTag(Tag tag, Theme theme, StringBuffer html, String path, int depth) {
    assert(tag != null);

    var anim = findAnimator(tag, theme);

    if (anim != null) {
      var node = new _AnimatedNode(path, depth, tag, anim, invalidate);
      var shadow = node.render(tag, theme);

      // Recurse.
      node.shadow = mountTag(shadow, theme, html, node.path, node.depth + 1);

      // This is last so that the shadows' callbacks happen before the parent.
      addRenderCallback(node.onRendered);

      return node;

    } else if (tag is ElementTag) {
      var node = new _ElementNode(path, depth, tag);
      _expandElement(node, theme, html);
      return node;

    } else if (tag is ThemeZone) {
      var node = new _ThemeNode(path, depth, tag);

      // Recurse.
      node.shadow = mountTag(node.tag.innerTag, node.tag.theme, html, node.path, node.depth + 1);

      return node;
    } else {
      throw "Unknown tag type: ${tag.runtimeType}";
    }
  }

  /// Returns the animator to be used to display the given Tag,
  /// or null if it should be handled as an HTML element.
  Animator findAnimator(Tag tag, Theme theme) {
    assert(tag.checked());

    // Does the theme have an animator?
    if (theme != null) {
      Animator anim = theme[tag.runtimeType];
      if (anim != null) {
        return anim;
      }
    }

    // Does the tag have an animator?
    Animator anim = tag.animator;
    if (anim != null) {
      return anim;
    }

    // Special forms.
    if (tag is ElementTag || tag is ThemeZone) {
      return null;
    }

    // Lookup failed.
    if (theme == null) {
      throw "There is no animator for ${tag.runtimeType} and no theme is installed";
    } else {
      throw "Theme ${theme.name} has no animator for ${runtimeType}";
    }
  }

  /// Render an HTML element by recursively expanding its children.
  void _expandElement(_ElementNode elt, Theme theme, StringBuffer out) {
    var tag = elt.tag;

    _writeStartTag(out, elt);

    if (tag.htmlTag == "textarea") {
      String val = elt.props["defaultValue"];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
      // TODO: other cases?

    } else {

      // Recurse.
      elt.children = expandInner(elt, theme, out, tag.inner);
    }

    out.write("</${tag.htmlTag}>");

    if (tag.ref != null) {
      _renderedRefs.add(elt);
    }
    if (tag.htmlTag == "form") {
      _mountedForms.add(elt);
    }
  }

  void _writeStartTag(StringBuffer out, _ElementNode elt) {
    out.write("<${elt.tag.htmlTag} data-path=\"${elt.path}\"");
    ElementType eltType = elt.tag.type;
    for (String key in elt.tag.props.keys) {
      var propType = eltType.propsByName[key];
      var val = elt.props[key];
      if (propType is HandlerType) {
        addHandler(propType.propKey, elt.path, val);
        continue;
      } else if (propType is AttributeType) {
        String escaped = HTML_ESCAPE.convert(_makeDomVal(key, val));
        out.write(" ${propType.propKey}=\"${escaped}\"");
      }
    }
    if (elt.tag.htmlTag == "input") {
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
    } else if (inner is Tag) {

      // Recurse.
      return _mountChildren(out, elt.path, elt.depth, [inner], theme);

    } else if (inner is Iterable) {

      List<Tag> children = [];
      for (var item in inner) {
        if (item is String) {
          children.add(_textType.makeTag({"inner": item}));
        } else if (item is Tag) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }

      // Recurse.
      return _mountChildren(out, elt.path, elt.depth, children, theme);
    }
    throw "unexpected type for an element's inner field: ${inner.runtimeType}";
  }

  List<_Node> _mountChildren(StringBuffer out, String parentPath, int parentDepth,
      List<Tag> children, Theme theme) {
    if (children.isEmpty) {
      return null;
    }

    int childDepth = parentDepth + 1;
    var result = <_Node>[];
    for (int i = 0; i < children.length; i++) {
      // Recurse.
      result.add(mountTag(children[i], theme, out, "${parentPath}/${i}", childDepth));
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