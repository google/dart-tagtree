part of render;

/// A Transaction mixin that implements updating views in place.
abstract class _Update extends _Mount with _Unmount {

  // Dependencies
  DomUpdater get dom;

  // What was updated
  final List<EventSink> _updatedWidgets = [];
  void setHandler(HandlerType type, String path, HandlerFunc handler);
  void removeHandler(HandlerType type, String path);

  // Either updates a view in place or unmounts and remounts it.
  // Returns the new view.
  _View updateOrReplace(_View current, TagNode next) {
    if (current.tag == next.tag) {
      _updateInPlace(current, next);
      return current;
    } else {
      String path = current.path;
      int depth = current.depth;
      unmount(current, willReplace: true);

      var html = new StringBuffer();
      _View result = mountView(next, html, path, depth);
      dom.replaceElement(path, html.toString());
      return result;
    }
  }

  /// Renders a Widget without any property changes.
  void updateWidget(_Widget view) {
    view.update(null);
    _renderWidget(view);
  }

  /// Updates a view in place.
  ///
  /// After the update, current should have the same props as next and any DOM changes
  /// needed should have been sent to frame.
  void _updateInPlace(_View view, TagNode newNode) {
    TagNode old = view.update(newNode);

    if (view is _Template) {
      _renderTemplate(view, old);
    } else if (view is _Widget) {
      _renderWidget(view);
    } else if (view is _Text) {
      _renderText(view, old);
    } else if (view is _Elt) {
      _renderElt(view, old);
    } else {
      throw "cannot update: ${view.runtimeType}";
    }
  }

  void _renderTemplate(_Template view, TagNode old) {
    TemplateTag tag = view.tag;
    if (tag.shouldUpdate != null && !tag.shouldUpdate(old.props, view.node.props)) {
      return;
    }
    TagNode newShadow = view.node.applyProps(tag.render);
    view.shadow = updateOrReplace(view.shadow, newShadow);
  }

  void _renderWidget(_Widget view) {
    var c = view.controller;
    TagNode newShadow = c.widget.render();
    view.shadow = updateOrReplace(view.shadow, newShadow);

    // Schedule events.
    if (c.didUpdate.hasListener) {
      _updatedWidgets.add(c.didUpdate);
    }
  }

  void _renderText(_Text view, TagNode old) {
    String newValue = view.node[#value];
    if (old[#value] != newValue) {
      dom.setInnerText(view.path, newValue);
    }
  }

  void _renderElt(_Elt elt, TagNode old) {
    _updateDomProperties(elt, old);
    _updateInner(elt);
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(_Elt elt, TagNode oldNode) {
    var tag = elt.tag;
    String path = elt.path;
    TagNode newNode = elt.node;

    // Delete any removed props
    for (Symbol key in oldNode.propKeys) {
      if (newNode[key] != null) {
        continue;
      }

      var type = tag.getPropType(key);
      if (type is HandlerType) {
        removeHandler(type, path);
      } else if (type is AttributeType) {
        dom.removeAttribute(path, type.name);
      }
    }

    // Update any new or changed props
    for (Symbol key in newNode.propKeys) {
      var oldVal = oldNode[key];
      var newVal = newNode[key];
      if (oldVal == newVal) {
        continue;
      }

      var type = tag.getPropType(key);
      if (type is HandlerType) {
        setHandler(type, path, newVal);
        continue;
      } else if (type is AttributeType) {
        String val = _makeDomVal(key, newVal);
        dom.setAttribute(path, type.name, val);
      }
    }
  }

  /// Updates the inner DOM and mount/unmounts children when needed.
  /// (Postcondition: _children and _childText are updated.)
  void _updateInner(_Elt elt) {
    String path = elt.path;
    var newInner = elt.node[#inner];

    if (newInner == null) {
      unmountInner(elt);
      var innerHtml = elt.node[#innerHtml];
      if (innerHtml != null) {
        dom.setInnerHtml(path, innerHtml);
      } else {
        dom.setInnerText(path, "");
      }
    } else if (newInner is String) {
      if (newInner == elt._childText) {
        return;
      }
      unmountInner(elt);
      dom.setInnerText(path, newInner);
      elt._childText = newInner;
    } else if (newInner is TagNode) {
      _updateChildren(elt, path, [newInner]);
    } else if (newInner is Iterable) {
      List<TagNode> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(new TagNode(const _TextTag(), {#value: item}));
        } else if (item is TagNode) {
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
  /// (Postcondition: _children and _childText are updated.)
  void _updateChildren(_Elt elt, String path, List<TagNode> newChildren) {
    if (elt._children == null) {
      StringBuffer out = new StringBuffer();
      mountInner(elt, out, newChildren, null);
      dom.setInnerHtml(path, out.toString());
      elt._childText = null;
      return;
    }

    int oldLength = elt._children.length;
    int newLength = newChildren.length;
    int addedChildCount = newLength - oldLength;

    List<_View> updatedChildren = [];
    // update or replace each child that's in both lists
    int endBoth = addedChildCount < 0 ? newLength  : oldLength;
    for (int i = 0; i < endBoth; i++) {
      _View before = elt._children[i];
      TagNode after = newChildren[i];
      assert(before != null);
      assert(after != null);
      updatedChildren.add(updateOrReplace(before, after));
    }

    if (addedChildCount < 0) {
      // trim to new size
      for (int i = oldLength - 1; i >= newLength; i--) {
        dom.removeChild(path, i);
      }
    } else if (addedChildCount > 0) {
      // append  children
      for (int i = oldLength; i < newLength; i++) {
        _View child = _mountNewChild(elt, newChildren[i], i);
        updatedChildren.add(child);
      }
    }
    elt._children = updatedChildren;
    elt._childText = null;
  }

  _View _mountNewChild(_Elt parent, TagNode child, int childIndex) {
    var html = new StringBuffer();
    _View view = mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    dom.addChildElement(parent.path, html.toString());
    return view;
  }
}