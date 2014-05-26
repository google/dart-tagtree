part of render;

/// A Transaction mixin that implements mounting views.
abstract class _Mount {

  // Dependencies
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
  _View mountView(TagNode node, StringBuffer html, String path, int depth) {
    _View view = _mountTag(node, html, path, depth);
    if (view.ref != null) {
      _mountedRefs.add(view);
    }
    return view;
  }

  _View _mountTag(TagNode node, StringBuffer out, String path, int depth) {
    Tag tag = node.tag;
    if (tag is _TextTag) {
      _TextView view = new _TextView(path, depth, node[#value]);
      // need to surround with a span to support incremental updates to a child
      out.write("<span data-path=${view.path}>${HTML_ESCAPE.convert(node[#value])}</span>");
      return view;

    } else if (tag is TemplateTag) {
      _TemplateView view = new _TemplateView(node, path, depth);
      TagNode shadow = node.applyProps(tag.render);
      view.shadow = mountView(shadow, out, path, depth + 1);
      return view;

    } else if (tag is WidgetTag) {
      var widget = tag.make();
      var view = new _WidgetView(node, path, depth);
      var c = widget.mount(node, () => invalidateWidget(view));
      view.controller = c;

      TagNode newShadow = widget.render();
      view.shadow = mountView(newShadow, out, view.path, view.depth + 1);

      if (c.didMount.hasListener) {
        _mountedWidgets.add(c.didMount);
      }

      return view;

    } else if (tag is ElementTag) {
      _EltView view = new _EltView(node, path, depth);
      _mountElt(view, out);
      return view;

    } else {
      throw "can't mount node for unknown tag type: ${tag.runtimeType}";
    }
  }

  void _mountElt(_EltView elt, StringBuffer out) {
    _writeStartTag(out, elt);

    if (elt.tagName == "textarea") {
      String val = elt.node[#defaultValue];
      if (val != null) {
        out.write(HTML_ESCAPE.convert(val));
      }
    } else {
      mountInner(elt, out, elt.node[#inner], elt.node[#innerHtml]);
    }

    out.write("</${elt.tagName}>");

    if (elt.tagName == "form") {
      _mountedForms.add(elt);
    }
  }

  void _writeStartTag(StringBuffer out, _EltView elt) {
    out.write("<${elt.tagName} data-path=\"${elt.path}\"");
    for (Symbol key in elt.node.propKeys) {
      var type = elt.tag.getPropType(key);
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
      String val = elt.node[#defaultValue];
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
    } else if (inner is TagNode) {
      elt._children = _mountChildren(out, elt.path, elt.depth, [inner]);
    } else if (inner is Iterable) {
      List<TagNode> children = [];
      for (var item in inner) {
        if (item is String) {
          children.add(new TagNode(const _TextTag(), {#value: item}));
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