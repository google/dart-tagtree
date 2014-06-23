part of render;

/// A Transaction mixin that implements updating a node tree and the DOM.
abstract class _Update extends _Mount with _Unmount {

  // Dependencies
  DomUpdater get dom;

  // What was updated
  void addRenderCallback(OnRendered callback);
  void setHandler(HandlerType type, String path, HandlerFunc handler);
  void removeHandler(HandlerType type, String path);

  /// Recursively renders the next view onto an existing node subtree.
  /// The node subtree will either be updated in place, or it will
  /// unmounted and a new subtree will be created.
  /// Either way, updates the DOM and returns the root node of the new subtree.
  _Node updateOrReplace(_Node node, View nextView, Theme oldTheme, Theme newTheme) {
    Animation nextAnim = findAnimation(nextView, newTheme);

    if (node is _AnimatedNode) {
      assert (node.anim != null);
      if (!node.anim.canPlay(nextView, nextAnim)) {
        return _replace(node, nextView, newTheme);
      }
      _updateShadow(node, nextView, oldTheme, newTheme);

    } else if (node is _ElementNode) {
      if (node.view.type != nextAnim) {
        return _replace(node, nextView, newTheme);
      }
      assert(node.anim == nextAnim);
      _updateElement(node, nextView, oldTheme, newTheme);

    } else {
      throw "unknown node type: ${node.runtimeType}";
    }

    return node;
  }

  /// Replace a node by unmounting and remounting. Any view state is lost.
  _Node _replace(_Node node, View nextView, Theme newTheme) {

    // cannot expand in place; unmount and remount
    String path = node.path;
    int depth = node.depth;
    unmount(node, willReplace: true);

    var html = new StringBuffer();
    _Node nextNode = mountView(nextView, newTheme, html, path, depth);
    dom.replaceElement(path, html.toString());
    return nextNode;
  }

  /// Recursively updates a node's shadow tree, using its current expander and the given view.
  ///
  /// After the update, all nodes in the subtree point to their newly-rendered Views
  /// and the DOM has been updated.
  void _updateShadow(_AnimatedNode node, View nextView, Theme oldTheme, Theme newTheme) {
    var oldView = node.view;
    var next = node.anim;

    if (oldTheme == newTheme && !next.shouldExpand(oldView, nextView)) {
      return; // Performance shortcut.
    }

    node.view = nextView;

    // Recurse.
    View shadowView = next.expand(nextView, node.nextState, node.refresh);
    node.shadow = updateOrReplace(node.shadow, shadowView, oldTheme, newTheme);

    // This is last so that the shadow's callbacks fire before the parent.
    if (next.onRendered != null) {
      addRenderCallback(next.onRendered);
    }
  }

  /// Recursively updates an HTML element and its children to match the given view.
  /// (The new view must have the same ElementType as the old.)
  void _updateElement(_ElementNode node, ElementView newView, Theme oldTheme, Theme newTheme) {
    assert(node.view.type == newView.type);

    _updateDomProperties(node.path, node.view, newView);

    // Recurse.
    _updateInner(node, newView, oldTheme, newTheme);
  }

  /// Updates the DOM attributes and event handlers of an element to match the node's view.
  void _updateDomProperties(String path, ElementView oldView, ElementView newView) {

    ElementType eltType = newView.type;
    PropsMap oldProps = oldView.props;
    PropsMap newProps = newView.props;

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

  /// Updates an element's inner HTML to match the given view's inner property.
  /// Recursively updates the children in the node tree as necessary.
  /// (Postcondition: _children and _childText are updated.)
  void _updateInner(_ElementNode elt, ElementView newView, Theme oldTheme, Theme newTheme) {
    elt.view = newView;

    String path = elt.path;
    var newInner = newView.inner;

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
      // Recurse.
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

      // Recurse.
      _updateChildren(elt, path, children, oldTheme, newTheme);

    } else {
      throw "invalid new value of inner: ${newInner.runtimeType}";
    }
  }

  /// Recursively updates the inner DOM and mounts/unmounts children when needed.
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
      assert(before != null && before.isMounted);
      assert(after != null);

      // Recurse.
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