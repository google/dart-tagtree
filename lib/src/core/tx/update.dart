part of core;

/// A Transaction mixin that implements updating views in place.
abstract class _Update extends _Mount with _Unmount {
  NextFrame get frame;

  // What was changed
  final List<Widget> _updatedWidgets = [];
  void setHandler(Symbol key, String path, EventHandler handler);
  void removeHandler(Symbol key, String path);

  View updateOrReplace(View current, View next) {
    if (canUpdateTo(current, next)) {
      update(current, next);
      return current;
    } else {
      String path = current.path;
      int depth = current.depth;
      unmount(current, willReplace: true);

      var html = new StringBuffer();
      mountView(next, html, path, depth);
      frame.replaceElement(path, html.toString());
      return next;
    }
  }

  /// Returns true if we can call update() to do an in-place update to a new version of a
  /// view. Otherwise, we must unmount the view and mount its replacement, so all state
  /// will be lost.
  bool canUpdateTo(View current, View next) {
    if (current is Text) {
      return (next is Text);
    } else if (current is Widget) {
      return current.runtimeType == next.runtimeType;
    } else if (current is Elt) {
      return (next is Elt) && current.tagName == next.tagName;
    } else {
      throw "cannot update: ${current.runtimeType}";
    }
  }

  /// Updates a view in place.
  ///
  /// After the update, it should have the same props as nextVersion and any DOM changes
  /// needed should have been sent to nextFrame for rendering.
  ///
  /// If nextVersion is null, the props are unchanged, but a stateful view may apply any pending
  /// state.
  void update(View current, View nextVersion) {
    if (current is Text) {
      _updateText(current, nextVersion);
    } else if (current is Widget) {
      _updateWidget(current, nextVersion);
    } else if (current is Elt) {
      _updateElt(current, nextVersion);
    } else {
      throw "cannot update: ${current.runtimeType}";
    }
  }

  void _updateText(Text current, Text next) {
    if (next == null || current.value == next.value) {
      return; // no internal state to update
    }
    current.value = next.value;
    frame.setInnerText(current.path, current.value);
  }

  void updateWidget(Widget current) {
    _updateWidget(current, null);
  }

  void _updateWidget(Widget current, Widget next) {
    View newShadow = current._updateAndRender(next);
    current._shadow = updateOrReplace(current._shadow, newShadow);
    if (current._didUpdate.hasListener) {
      _updatedWidgets.add(current);
    }
  }

  void _updateElt(Elt elt, Elt nextVersion) {
    String path = elt.path;
    assert(path != null);
    if (nextVersion == null) {
      return; // no internal state to update
    }

    Map<Symbol, dynamic> oldProps = elt._props;
    Map<Symbol, dynamic> newProps = nextVersion._props;

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
    } else if (newInner is View) {
      _updateChildren(elt, path, [newInner]);
    } else if (newInner is Iterable) {
      List<View> children = [];
      for (var item in newInner) {
        if (item is String) {
          children.add(new Text(item));
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
  /// (Postcondition: _children and _childText are updated.)
  void _updateChildren(_Inner elt, String path, List<View> newChildren) {

    if (elt._children == null) {
      StringBuffer out = new StringBuffer();
      mountInner(elt, out, newChildren, null);
      frame.setInnerHtml(path, out.toString());
      elt._children = newChildren;
      elt._childText = null;
      return;
    }

    List<View> updatedChildren = [];
    // update or replace each child that's in both lists
    int endBoth = elt._children.length < newChildren.length ? elt._children.length : newChildren.length;
    int childDepth = elt.depth + 1;
    for (int i = 0; i < endBoth; i++) {
      View before = elt._children[i];
      View after = newChildren[i];
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
        View child = newChildren[i];
        _mountNewChild(elt, child, i);
        updatedChildren.add(child);
      }
    }
    elt._children = updatedChildren;
    elt._childText = null;
  }

  void _mountNewChild(_Inner parent, View child, int childIndex) {
    var html = new StringBuffer();
    mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame.addChildElement(parent.path, html.toString());
  }
}