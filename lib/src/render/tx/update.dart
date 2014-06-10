part of render;

/// A Transaction mixin that implements updating a node tree and the DOM.
abstract class _Update extends _Mount with _Unmount {

  // Dependencies
  DomUpdater get dom;

  // What was updated
  final List<EventSink> _renderedWidgets = [];
  void setHandler(HandlerType type, String path, HandlerFunc handler);
  void removeHandler(HandlerType type, String path);

  // Renders the given view into an existing node tree.
  // The node tree will either be updated in place, or it will
  // unmounted and a new node tree will be created.
  // Either way, updates the DOM and returns the new node tree.
  _Node updateOrReplace(_Node current, View toRender, Theme nextTheme) {
    if (current.view.tag == toRender.tag && current.theme == nextTheme) {
      _updateInPlace(current, toRender, nextTheme);
      return current;
    } else {
      String path = current.path;
      int depth = current.depth;
      unmount(current, willReplace: true);

      var html = new StringBuffer();
      _Node result = mountView(toRender, nextTheme, html, path, depth);
      dom.replaceElement(path, html.toString());
      return result;
    }
  }

  /// Renders a Widget without any property changes.
  void updateWidget(_WidgetNode node) {
    Widget w = node.controller.widget;
    var oldState = w.state;
    w.commitState();
    _renderWidget(node, node.view, oldState);
  }

  /// Updates a node tree in place, by expanding a View.
  /// Assumes the node's theme didn't change.
  ///
  /// After the update, all nodes in the subtree point to their newly-rendered Views
  /// and the DOM has been updated.
  void _updateInPlace(_Node node, View toRender, Theme nextTheme) {
    View old = node.updateProps(toRender);

    if (node is _TemplateNode) {
      _renderTemplate(node, old);
    } else if (node is _WidgetNode) {
      Widget w = node.controller.widget;
      var oldState = w.state;
      w.commitState();
      _renderWidget(node, old, oldState);
    } else if (node is _TextNode) {
      _renderText(node, old);
    } else if (node is _ElementNode) {
      _renderElt(node, old.props);
    } else {
      throw "cannot update: ${node.runtimeType}";
    }
  }

  void _renderTemplate(_TemplateNode node, View old) {
    if (!node.template.shouldRender(old, node.view)) {
      return;
    }
    View newShadow = node.template.render(node.view);
    node.shadow = updateOrReplace(node.shadow, newShadow, node.theme);
  }

  void _renderWidget(_WidgetNode node, View oldView, oldState) {
    if (!node.controller.widget.shouldRender(oldView, oldState)) {
      return;
    }

    var c = node.controller;
    View newShadow = c.widget.render();
    node.shadow = updateOrReplace(node.shadow, newShadow, node.theme);

    // Schedule events.
    if (c.didRender.hasListener) {
      _renderedWidgets.add(c.didRender);
    }
  }

  void _renderText(_TextNode node, _TextView oldView) {
    String newValue = node.view.value;
    if (oldView.value != newValue) {
      dom.setInnerText(node.path, newValue);
    }
  }

  void _renderElt(_ElementNode elt, PropsMap oldProps) {
    _updateDomProperties(elt, oldProps);
    _updateInner(elt);
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(_ElementNode elt, PropsMap oldProps) {
    ElementType eltType = elt.view.tag;
    String path = elt.path;
    PropsMap newProps = elt.view.props;

    // Delete any removed props
    for (String key in oldProps.keys) {
      if (newProps[key] != null) {
        continue;
      }

      var propType = eltType.propsByName[key];
      if (propType is HandlerType) {
        removeHandler(propType, path);
      } else if (propType is AttributeType) {
        dom.removeAttribute(path, propType.propKey);
      }
    }

    // Update any new or changed props
    for (String key in newProps.keys) {
      var oldVal = oldProps[key];
      var newVal = newProps[key];
      if (oldVal == newVal) {
        continue;
      }

      var type = eltType.propsByName[key];
      if (type is HandlerType) {
        setHandler(type, path, newVal);
        continue;
      } else if (type is AttributeType) {
        String val = _makeDomVal(key, newVal);
        dom.setAttribute(path, type.propKey, val);
      }
    }
  }

  /// Updates the inner DOM and mount/unmounts children when needed.
  /// (Postcondition: _children and _childText are updated.)
  void _updateInner(_ElementNode elt) {
    String path = elt.path;
    var newInner = elt.view.inner;

    if (newInner == null) {
      unmountInner(elt);
      dom.setInnerText(path, "");
    } else if (newInner is String) {
      if (newInner == elt.children) {
        return;
      }
      unmountInner(elt);
      dom.setInnerText(path, newInner);
      elt.children = newInner;
    } else if (newInner is RawHtml) {
      if (newInner == elt.children) {
        return;
      }
      unmountInner(elt);
      dom.setInnerHtml(path, newInner.html);
      elt.children = newInner;
    } else if (newInner is View) {
      _updateChildren(elt, path, [newInner]);
    } else if (newInner is Iterable) {
      List<View> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(new _TextView(item));
        } else if (item is View) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      _updateChildren(elt, path, children);
    } else {
      throw "invalid new value of inner: ${newInner.runtimeType}";
    }
  }

  /// Updates the inner DOM and mounts/unmounts children when needed.
  /// (Postcondition: _children,  _childText, and _childHtml are updated.)
  void _updateChildren(_ElementNode elt, String path, List<View> newChildren) {
    if (!(elt.children is List)) {
      StringBuffer out = new StringBuffer();
      elt.children = expandInner(elt, out, newChildren);
      dom.setInnerHtml(path, out.toString());
      return;
    }

    int oldLength = elt.children.length;
    int newLength = newChildren.length;
    int addedChildCount = newLength - oldLength;

    List<_Node> updatedChildren = [];
    // update or replace each child that's in both lists
    int endBoth = addedChildCount < 0 ? newLength  : oldLength;
    for (int i = 0; i < endBoth; i++) {
      _Node before = elt.children[i];
      View after = newChildren[i];
      assert(before != null);
      assert(after != null);
      updatedChildren.add(updateOrReplace(before, after, before.theme));
    }

    if (addedChildCount < 0) {
      // trim to new size
      for (int i = oldLength - 1; i >= newLength; i--) {
        dom.removeChild(path, i);
      }
    } else if (addedChildCount > 0) {
      // append  children
      for (int i = oldLength; i < newLength; i++) {
        _Node child = _mountNewChild(elt, newChildren[i], i);
        updatedChildren.add(child);
      }
    }
    elt.children = updatedChildren;
  }

  _Node _mountNewChild(_ElementNode parent, View child, int childIndex) {
    var html = new StringBuffer();
    _Node view = mountView(child, parent.theme, html,
        "${parent.path}/${childIndex}", parent.depth + 1);
    dom.addChildElement(parent.path, html.toString());
    return view;
  }
}