part of render;

/// A Transaction mixin that implements updating a node tree and the DOM.
abstract class _Update extends _Mount with _Unmount {

  // Dependencies
  DomUpdater get dom;

  // What was updated
  void setHandler(HandlerType type, String path, HandlerFunc handler);
  void removeHandler(HandlerType type, String path);

  /// Renders the next animation frame for the given node, if needed.
  /// Cuts to a new animation if needed, otherwise continues the current animation.
  /// The node subtree will either be updated in place (if the animation continues),
  /// or it will unmounted and a new subtree will be created (if there is a cut).
  /// Either way, updates the DOM and returns the root node of the new subtree.
  _Node updateOrReplace(_Node node, Tag nextTag, Theme oldTheme, Theme newTheme) {
    Animator nextAnim = findAnimator(nextTag, newTheme);

    if (node is _AnimatedNode) {
      if (node.shouldCut(nextTag, nextAnim)) {
        return _replace(node, nextTag, newTheme);
      }
      _updateShadow(node, nextTag, oldTheme, newTheme);
      return node;

    } else if (node is _ElementNode) {
      if (nextAnim == null && nextTag is ElementTag) {
        _updateElement(node, nextTag, oldTheme, newTheme);
        return node;
      } else {
        return _replace(node, nextTag, newTheme);
      }

    } else if (node is _ThemeNode) {
      if (nextAnim == null && nextTag is ThemeZone) {
        _updateThemeZone(node, nextTag);
        return node;
      } else {
        return _replace(node, nextTag, newTheme);
      }
    } else {
      throw "unknown node type: ${node.runtimeType}";
    }

  }

  /// Replace a node and cut to a new animation. This replaces the Place,
  /// so any animation-specific state is lost.
  _Node _replace(_Node node, Tag nextTag, Theme newTheme) {

    // unmount old animation
    String path = node.path;
    int depth = node.depth;
    unmount(node, willReplace: true);

    // render new animation
    var html = new StringBuffer();
    _Node nextNode = mountTag(nextTag, newTheme, html, path, depth);
    dom.replaceElement(path, html.toString());
    return nextNode;
  }

  /// Renders another frame in an animation, if needed.
  /// Recursively updates the node's shadow tree.
  ///
  /// After the update, all nodes in the subtree point to their newly-rendered Tags
  /// and the DOM has been updated.
  void _updateShadow(_AnimatedNode node, Tag nextTag, Theme oldTheme, Theme newTheme) {
    if (oldTheme == newTheme && !node.isDirty(nextTag)) {
      return; // Skip this frame. (Performance shortcut.)
    }

    Tag shadowTree = node.render(nextTag, newTheme);

    // Recurse.
    node.shadow = updateOrReplace(node.shadow, shadowTree, oldTheme, newTheme);

    // This is last so that the shadow's callbacks fire before the parent.
    addRenderCallback(node.onRendered);
  }

  void _updateThemeZone(_ThemeNode node, ThemeZone next) {
    ThemeZone prev = node.tag;
    if (prev.theme == next.theme && prev.innerTag == next.innerTag) {
      return; // Nothing to do
    }

    // Recurse.
    node.tag = next;
    node.shadow = updateOrReplace(node.shadow, next.innerTag, prev.theme, next.theme);
  }

  /// Recursively updates an HTML element and its children to match the given tag.
  /// (The new tag must have the same ElementType as the old.)
  void _updateElement(_ElementNode node, ElementTag newTag, Theme oldTheme, Theme newTheme) {
    assert(node.tag.type == newTag.type);

    _updateDomProperties(node.path, node.tag, newTag);

    // Recurse.
    _updateInner(node, newTag, oldTheme, newTheme);
  }

  /// Updates the DOM attributes and event handlers of an element to match the new tag.
  void _updateDomProperties(String path, ElementTag oldTag, ElementTag newTag) {

    ElementType eltType = newTag.type;
    PropsMap oldProps = oldTag.props;
    PropsMap newProps = newTag.props;

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

    var ref = oldTag.ref;
    if (ref != null) {
      dom.detachRef(ref);
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

    ref = newTag.ref;
    if (ref != null) {
      dom.attachRef(path, ref);
    }
  }

  /// Updates an element's inner HTML to match the new tag's inner property.
  /// Recursively updates the children in the node tree as necessary.
  /// (Postcondition: _children and _childText are updated.)
  void _updateInner(_ElementNode elt, ElementTag newTag, Theme oldTheme, Theme newTheme) {
    elt.tag = newTag;

    String path = elt.path;
    var newInner = newTag.inner;

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

    } else if (newInner is Tag) {
      // Recurse.
      _updateChildren(elt, path, [newInner], oldTheme, newTheme);

    } else if (newInner is Iterable) {
      List<Tag> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(_textType.makeTag({"inner": item}));
        } else if (item is Tag) {
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
  void _updateChildren(_ElementNode elt, String path, List<Tag> newChildren,
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
      Tag after = newChildren[i];
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

  _Node _mountNewChild(_ElementNode parent, Tag child, int childIndex, Theme newTheme) {
    var html = new StringBuffer();
    _Node node = mountTag(child, newTheme, html,
        "${parent.path}/${childIndex}", parent.depth + 1);
    dom.addChildElement(parent.path, html.toString());
    return node;
  }
}