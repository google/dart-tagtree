part of render;

/// A Transaction mixin that implements updating a node tree and the DOM.
abstract class _Update extends _Mount with _Unmount {

  // Dependencies
  DomUpdater get dom;

  // What was updated
  final List<OnRendered> _renderedExpanders = [];
  void setHandler(HandlerType type, String path, HandlerFunc handler);
  void removeHandler(HandlerType type, String path);

  // Renders the given view into an existing node tree.
  // The node tree will either be updated in place, or it will
  // unmounted and a new node tree will be created.
  // Either way, updates the DOM and returns the new node tree.
  _Node updateOrReplace(_Node current, View toRender, Theme oldTheme, Theme newTheme) {

    var nextExpander = toRender.createExpanderForTheme(newTheme);

    if (current is _ElementNode && nextExpander is ElementType &&
        current.view.type == nextExpander) {
      updateElementInPlace(current, toRender, oldTheme, newTheme);
      return current;
    } else if (current is _ExpandedNode && current.expander.canReuse(nextExpander))  {
      updateInPlace(current, toRender, oldTheme, newTheme);
      return current;
    } else {
      String path = current.path;
      int depth = current.depth;
      unmount(current, willReplace: true);

      var html = new StringBuffer();
      _Node result = mountView(toRender, newTheme, html, path, depth);
      dom.replaceElement(path, html.toString());
      return result;
    }
  }

  /// Updates a node tree in place, by expanding a View.
  ///
  /// After the update, all nodes in the subtree point to their newly-rendered Views
  /// and the DOM has been updated.
  void updateInPlace(_ExpandedNode node, View newView, Theme oldTheme, Theme newTheme) {
    var oldView = node.view;
    var expander = node.expander;
    if (oldTheme == newTheme && !expander.shouldExpand(oldView, newView)) {
      return;
    }

    View newShadow = expander.expand(newView);
    if (expander.onRendered != null) {
      _renderedExpanders.add(expander.onRendered);
    }

    node.view = newView;
    if (newShadow != newView) {
      node.shadow = updateOrReplace(node.shadow, newShadow, oldTheme, newTheme);
    }
  }

  _cast(x) => x;

  void updateElementInPlace(_ElementNode node, ElementView newView,
                            Theme oldTheme, Theme newTheme) {
    var oldView = node.view;
    node.view = newView;
    _updateDomProperties(node, oldView.props);
    _updateInner(node, oldTheme, newTheme);
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(_ElementNode elt, PropsMap oldProps) {
    ElementType eltType = elt.view.type;
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
  void _updateInner(_ElementNode elt, Theme oldTheme, Theme newTheme) {
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
      _updateChildren(elt, path, [newInner], oldTheme, newTheme);
    } else if (newInner is Iterable) {
      List<View> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(_textType.makeView({"inner": item}));
        } else if (item is View) {
          children.add(item);
        } else {
          throw "bad item in inner: ${item}";
        }
      }
      _updateChildren(elt, path, children, oldTheme, newTheme);
    } else {
      throw "invalid new value of inner: ${newInner.runtimeType}";
    }
  }

  /// Updates the inner DOM and mounts/unmounts children when needed.
  /// (Postcondition: _children,  _childText, and _childHtml are updated.)
  void _updateChildren(_ElementNode elt, String path, List<View> newChildren,
                       Theme oldTheme, Theme newTheme) {
    if (!(elt.children is List)) {
      StringBuffer out = new StringBuffer();
      elt.children = expandInner(elt, newTheme, out, newChildren);
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
      updatedChildren.add(updateOrReplace(before, after, oldTheme, newTheme));
    }

    if (addedChildCount < 0) {
      // trim to new size
      for (int i = oldLength - 1; i >= newLength; i--) {
        dom.removeChild(path, i);
      }
    } else if (addedChildCount > 0) {
      // append  children
      for (int i = oldLength; i < newLength; i++) {
        _Node child = _mountNewChild(elt, newChildren[i], i, newTheme);
        updatedChildren.add(child);
      }
    }
    elt.children = updatedChildren;
  }

  _Node _mountNewChild(_ElementNode parent, View child, int childIndex, Theme newTheme) {
    var html = new StringBuffer();
    _Node view = mountView(child, newTheme, html,
        "${parent.path}/${childIndex}", parent.depth + 1);
    dom.addChildElement(parent.path, html.toString());
    return view;
  }
}