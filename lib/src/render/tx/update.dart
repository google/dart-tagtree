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
  _View updateOrReplace(_View current, TaggedNode next) {
    if (current.node.tag == next.tag) {
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
  void updateWidget(_WidgetView view) {
    Widget w = view.controller.widget;
    var oldState = w.state;
    w.commitState();
    _renderWidget(view, view.node, oldState);
  }

  /// Updates a view in place.
  ///
  /// After the update, current should have the same props as next and any DOM changes
  /// needed should have been sent to frame.
  void _updateInPlace(_View view, TaggedNode newNode) {
    TaggedNode old = view.updateProps(newNode);

    if (view is _TemplateView) {
      _renderTemplate(view, old);
    } else if (view is _WidgetView) {
      Widget w = view.controller.widget;
      var oldState = w.state;
      w.commitState();
      _renderWidget(view, old, oldState);
    } else if (view is _TextView) {
      _renderText(view, old);
    } else if (view is _EltView) {
      _renderElt(view, old);
    } else {
      throw "cannot update: ${view.runtimeType}";
    }
  }

  void _renderTemplate(_TemplateView view, TaggedNode old) {
    if (!view.renderer.shouldRender(old, view.node)) {
      return;
    }
    TaggedNode newShadow = view.renderer.render(view.node);
    view.shadow = updateOrReplace(view.shadow, newShadow);
  }

  void _renderWidget(_WidgetView view, TaggedNode oldNode, oldState) {
    if (!view.controller.widget.shouldRender(oldNode, oldState)) {
      return;
    }

    var c = view.controller;
    TaggedNode newShadow = c.widget.render();
    view.shadow = updateOrReplace(view.shadow, newShadow);

    // Schedule events.
    if (c.didUpdate.hasListener) {
      _updatedWidgets.add(c.didUpdate);
    }
  }

  void _renderText(_TextView view, _TextNode node) {
    String newValue = view.node.value;
    if (node.value != newValue) {
      dom.setInnerText(view.path, newValue);
    }
  }

  void _renderElt(_EltView elt, ElementNode old) {
    _updateDomProperties(elt, old);
    _updateInner(elt);
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(_EltView elt, ElementNode old) {
    ElementTag tag = elt.eltTag;
    String path = elt.path;
    ElementNode newNode = elt.node;

    // Delete any removed props
    for (String key in old.keys) {
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
    for (String key in newNode.keys) {
      var oldVal = old[key];
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
  void _updateInner(_EltView elt) {
    String path = elt.path;
    var newInner = elt.node["inner"];

    if (newInner == null) {
      unmountInner(elt);
      var innerHtml = elt.node["innerHtml"];
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
    } else if (newInner is TaggedNode) {
      _updateChildren(elt, path, [newInner]);
    } else if (newInner is Iterable) {
      List<TaggedNode> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(new _TextNode(item));
        } else if (item is TaggedNode) {
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
  void _updateChildren(_EltView elt, String path, List<TaggedNode> newChildren) {
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
      TaggedNode after = newChildren[i];
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

  _View _mountNewChild(_EltView parent, ElementNode child, int childIndex) {
    var html = new StringBuffer();
    _View view = mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    dom.addChildElement(parent.path, html.toString());
    return view;
  }
}