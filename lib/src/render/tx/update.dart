part of render;

/// A Transaction mixin that implements updating views in place.
abstract class _Update extends _Mount with _Unmount {

  // Dependencies
  HtmlSchema get html;
  DomUpdater get dom;

  // What was updated
  final List<EventSink> _updatedWidgets = [];
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
      dom.replaceElement(path, html.toString());
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
    } else if (current is _Widget) {
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
    TemplateDef def = current.def;
    Props next = new Props(nextTag.props);
    if (!def.shouldUpdate(current.props, next)) {
      return;
    }
    Tag newShadow = def.render(nextTag.props);
    current.shadow = updateOrReplace(current.shadow, newShadow);
    current.props = next;
  }

  void updateWidget(_Widget v, [Tag next]) {
    var c = v.controller;
    var w = c.widget;

    // Update the widget
    if (next != null && !w.shouldUpdate(next)) {
      return;
    }
    assert(w.isMounted);
    w.updateState();
    if (next != null) {
      c.setProps(next.props);
    }
    Tag newShadow = w.render();

    // Update the DOM
    v.shadow = updateOrReplace(v.shadow, newShadow);

    // Schedule the didUpdate event
    if (c.didUpdate.hasListener) {
      _updatedWidgets.add(c.didUpdate);
    }
  }

  void _updateText(_Text current, Tag nextTag) {
    String next = nextTag.props[#value];
    if (current.value == next) {
      return; // no internal state to update
    }
    current.value = next;
    dom.setInnerText(current.path, current.value);
  }

  void _updateElt(_Elt elt, Tag next) {
    String path = elt.path;
    assert(path != null);

    Map<Symbol, dynamic> oldProps = elt.props;
    Map<Symbol, dynamic> newProps = next.props;

    elt.props = newProps;
    _updateDomProperties(path, oldProps, newProps);
    _updateInner(elt, path, newProps[#inner], newProps[#innerHtml]);
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(String eltPath, Map<Symbol, dynamic> oldProps,
                            Map<Symbol, dynamic> newProps) {

    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (newProps.containsKey(key)) {
        continue;
      }

      if (html.handlerNames.containsKey(key)) {
        removeHandler(key, eltPath);
      } else if (html.atts.containsKey(key)) {
        dom.removeAttribute(eltPath, html.atts[key]);
      }
    }

    // Update any new or changed props
    for (Symbol key in newProps.keys) {
      var oldVal = oldProps[key];
      var newVal = newProps[key];
      if (oldVal == newVal) {
        continue;
      }

      if (html.handlerNames.containsKey(key)) {
        setHandler(key, eltPath, newVal);
      } else if (html.atts.containsKey(key)) {
        String name = html.atts[key];
        String val = _makeDomVal(key, newVal);
        dom.setAttribute(eltPath, name, val);
      }
    }
  }

  /// Updates the inner DOM and mount/unmounts children when needed.
  /// (Postcondition: _children and _childText are updated.)
  void _updateInner(_Elt elt, String path, newInner, newInnerHtml) {
    if (newInner == null) {
      unmountInner(elt);
      if (newInnerHtml != null) {
        dom.setInnerHtml(path, newInnerHtml);
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
  void _updateChildren(_Elt elt, String path, List<Tag> newChildren) {

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
      Tag after = newChildren[i];
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

  _View _mountNewChild(_Elt parent, Tag child, int childIndex) {
    var html = new StringBuffer();
    _View view = mountView(child, html, "${parent.path}/${childIndex}", parent.depth + 1);
    dom.addChildElement(parent.path, html.toString());
    return view;
  }
}