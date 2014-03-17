part of core;

/// A Transaction mixin that implements updating views in place.
abstract class _Update extends _Mount with _Unmount {

  // What was done
  final List<Widget> _updatedWidgets = [];

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
    frame
        ..visit(current.path)
        ..setInnerText(current.value);
  }

  void _updateWidget(Widget current, Widget next) {
    View newShadow = current._updateAndRender(next);

    if (current._shadow.canUpdateTo(newShadow)) {
      update(current._shadow, newShadow);
    } else {
      _mountReplacementShadow(current, newShadow);
      current._shadow = newShadow;
    }
    if (current._didUpdate.hasListener) {
      _updatedWidgets.add(current);
    }
  }

  void _mountReplacementShadow(Widget owner, View newShadow) {
    // TODO: no longer need to visit early
    String path = owner.path;
    frame.visit(path);
    unmount(owner._shadow);

    var html = new StringBuffer();
    mountView(newShadow, html, path, owner.depth + 1);
    frame.replaceElement(html.toString());
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
    frame.visit(eltPath);

    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (newProps.containsKey(key)) {
        continue;
      }

      if (dispatcher.isHandlerKey(key)) {
        dispatcher.removeHandler(key, eltPath);
      } else if (_allAtts.containsKey(key)) {
        frame.removeAttribute(_allAtts[key]);
      }
    }

    // Update any new or changed props
    for (Symbol key in newProps.keys) {
      var oldVal = oldProps[key];
      var newVal = newProps[key];
      if (oldVal == newVal) {
        continue;
      }

      if (dispatcher.isHandlerKey(key)) {
        dispatcher.setHandler(key, eltPath, newVal);
      } else if (_allAtts.containsKey(key)) {
        String name = _allAtts[key];
        String val = _makeDomVal(key, newVal);
        frame.setAttribute(name, val);
      }
    }
  }

  /// Updates the inner DOM and mount/unmounts children when needed.
  /// (Postcondition: _children and _childText are updated.)
  void _updateInner(_Inner elt, String path, newInner, newInnerHtml) {
    if (newInner == null) {
      unmountInner(elt);
      frame.visit(path);
      if (newInnerHtml != null) {
        frame.setInnerHtml(newInnerHtml);
      } else {
        frame.setInnerText("");
      }
    } else if (newInner is String) {
      if (newInner == elt._childText) {
        return;
      }
      unmountInner(elt);
      frame
          ..visit(path)
          ..setInnerText(newInner);
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
      frame
          ..visit(path)
          ..setInnerHtml(out.toString());
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
      assert(before != null);
      View after = newChildren[i];
      assert(after != null);
      if (before.canUpdateTo(after)) {
        // note: update may call frame.visit()
        update(before, after);
        updatedChildren.add(before);
      } else {
        unmount(before);
        _mountReplacementChild(elt, after, i);
        updatedChildren.add(after);
      }
    }

    int extraChildren = newChildren.length - elt._children.length;
    if (extraChildren < 0) {
      // trim to new size
      frame.visit(path);
      for (int i = elt._children.length - 1; i >= newChildren.length; i--) {
        frame.removeChild(i);
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
    frame
      ..visit(parent.path)
      ..addChildElement(html.toString());
  }

  void _mountReplacementChild(_Inner parent, View child, int childIndex) {
    StringBuffer html = new StringBuffer();
    mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    frame
        ..visit(parent.path)
        ..replaceChildElement(childIndex, html.toString());
  }
}