part of core;

/// A Transaction mixin that implements updating views in place.
abstract class _Update extends _Mount with _Unmount {
  NextFrame get frame;

  // What was changed
  final List<Widget> _updatedWidgets = [];
  void setHandler(Symbol key, String path, EventHandler handler);
  void removeHandler(Symbol key, String path);

  // Either updates a view in place or unmounts and remounts it.
  // Returns the new view.
  _View updateOrReplace(_View current, Tag next) {
    if (current.def == next.def) {
      _updateInPlace(current, next);
      return current;
    } else {
      String path = current.path;
      int depth = current.depth;
      unmount(current, willReplace: true);

      var html = new StringBuffer();
      _View result = mountView(next, html, path, depth);
      frame.replaceElement(path, html.toString());
      return result;
    }
  }

  /// Updates a view in place.
  ///
  /// After the update, current should have the same props as next and any DOM changes
  /// needed should have been sent to frame.
  void _updateInPlace(_View current, Tag next) {
    if (current is _Template) {
      _updateTemplate(current, next);
    } else if (current is WidgetView) {
      updateWidget(current, next);
    } else if (current is _Text) {
      _updateText(current, next);
    } else if (current is _Elt) {
      _updateElt(current, next);
    } else {
      throw "cannot update: ${current.runtimeType}";
    }
  }

  void _updateTemplate(_Template current, Tag nextTag) {
    TagDef def = current.def;
    Props next = new Props(nextTag.props);
    if (!def._shouldUpdate(current._props, next)) {
      return;
    }
    Tag newShadow = def._render(nextTag.props);
    current._shadow = updateOrReplace(current._shadow, newShadow);
    current._props = next;
  }

  void updateWidget(WidgetView view, [Tag next]) {
    Widget current = view.widget;
    if (next != null && !current.shouldUpdate(next)) {
      return;
    }
    Tag newShadow = current._updateAndRender(next);
    view._shadow = updateOrReplace(view._shadow, newShadow);
    if (current._didUpdate.hasListener) {
      _updatedWidgets.add(current);
    }
  }

  void _updateText(_Text current, Tag nextTag) {
    String next = nextTag.props[#value];
    if (current.value == next) {
      return; // no internal state to update
    }
    current.value = next;
    frame.setInnerText(current.path, current.value);
  }

  void _updateElt(_Elt elt, Tag next) {
    String path = elt.path;
    assert(path != null);

    Map<Symbol, dynamic> oldProps = elt._props;
    Map<Symbol, dynamic> newProps = next.props;

    elt._props = newProps;
    _updateDomProperties(path, oldProps, newProps);
    _updateInner(elt, path, newProps[#inner], newProps[#innerHtml]);
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(String eltPath, Map<Symbol, dynamic> oldProps, Map<Symbol, dynamic> newProps) {

    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (newProps.containsKey(key)) {
        continue;
      }

      if (allHandlerKeys.contains(key)) {
        removeHandler(key, eltPath);
      } else if (_allAtts.containsKey(key)) {
        frame.removeAttribute(eltPath, _allAtts[key]);
      }
    }

    // Update any new or changed props
    for (Symbol key in newProps.keys) {
      var oldVal = oldProps[key];
      var newVal = newProps[key];
      if (oldVal == newVal) {
        continue;
      }

      if (allHandlerKeys.contains(key)) {
        setHandler(key, eltPath, newVal);
      } else if (_allAtts.containsKey(key)) {
        String name = _allAtts[key];
        String val = _makeDomVal(key, newVal);
        frame.setAttribute(eltPath, name, val);
      }
    }
  }

  /// Updates the inner DOM and mount/unmounts children when needed.
  /// (Postcondition: _children and _childText are updated.)
  void _updateInner(_Inner elt, String path, newInner, newInnerHtml) {
    if (newInner == null) {
      unmountInner(elt);
      if (newInnerHtml != null) {
        frame.setInnerHtml(path, newInnerHtml);
      } else {
        frame.setInnerText(path, "");
      }
    } else if (newInner is String) {
      if (newInner == elt._childText) {
        return;
      }
      unmountInner(elt);
      frame.setInnerText(path, newInner);
      elt._childText = newInner;
    } else if (newInner is Tag) {
      _updateChildren(elt, path, [newInner]);
    } else if (newInner is Iterable) {
      List<Tag> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(TextDef.instance.makeTag({#value: item}));
        } else if (item is Tag) {
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
  void _updateChildren(_Inner elt, String path, List<Tag> newChildren) {

    if (elt._children == null) {
      StringBuffer out = new StringBuffer();
      mountInner(elt, out, newChildren, null);
      frame.setInnerHtml(path, out.toString());
      elt._childText = null;
      return;
    }

    List<_View> updatedChildren = [];
    // update or replace each child that's in both lists
    int endBoth = elt._children.length < newChildren.length ? elt._children.length : newChildren.length;
    int childDepth = elt.depth + 1;
    for (int i = 0; i < endBoth; i++) {
      _View before = elt._children[i];
      Tag after = newChildren[i];
      assert(before != null);
      assert(after != null);
      updatedChildren.add(updateOrReplace(before, after));
    }

    int extraChildren = newChildren.length - elt._children.length;
    if (extraChildren < 0) {
      // trim to new size
      for (int i = elt._children.length - 1; i >= newChildren.length; i--) {
        frame.removeChild(path, i);
      }
    } else if (extraChildren > 0) {
      // append  children
      for (int i = elt._children.length; i < newChildren.length; i++) {
        _View child = _mountNewChild(elt, newChildren[i], i);
        updatedChildren.add(child);
      }
    }
    elt._children = updatedChildren;
    elt._childText = null;
  }

  _View _mountNewChild(_Inner parent, Tag child, int childIndex) {
    var html = new StringBuffer();
    _View view = mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame.addChildElement(parent.path, html.toString());
    return view;
  }
}