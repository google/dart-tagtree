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
    if (current.def == next.tag) {
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
  void _updateInPlace(_View current, TagNode next) {
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

  void _updateTemplate(_Template current, TagNode nextTag) {
    TemplateTag def = current.def;
    if (def.shouldUpdate != null && !def.shouldUpdate(current.props, nextTag.props)) {
      return;
    }
    TagNode newShadow = def.renderProps(nextTag.propMap);
    current.shadow = updateOrReplace(current.shadow, newShadow);
    current.props = nextTag.props;
  }

  void updateWidget(_Widget v, [TagNode next]) {
    var c = v.controller;
    var w = c.widget;

    // Update the widget
    if (next != null && !w.shouldUpdate(next)) {
      return;
    }
    assert(w.isMounted);
    w.commitState();
    if (next != null) {
      c.setProps(next.propMap);
    }
    TagNode newShadow = w.render();

    // Update the DOM
    v.shadow = updateOrReplace(v.shadow, newShadow);

    // Schedule the didUpdate event
    if (c.didUpdate.hasListener) {
      _updatedWidgets.add(c.didUpdate);
    }
  }

  void _updateText(_Text current, TagNode nextTag) {
    String next = nextTag.props[#value];
    if (current.value == next) {
      return; // no internal state to update
    }
    current.value = next;
    dom.setInnerText(current.path, current.value);
  }

  void _updateElt(_Elt elt, TagNode next) {
    String path = elt.path;
    assert(path != null);

    Map<Symbol, dynamic> oldProps = elt.props;
    Map<Symbol, dynamic> newProps = next.propMap;

    elt.props = newProps;
    _updateDomProperties(elt.def, path, oldProps, newProps);
    _updateInner(elt, path, newProps[#inner], newProps[#innerHtml]);
  }

  /// Updates DOM attributes and event handlers of an Elt.
  void _updateDomProperties(ElementTag tag, String eltPath, Map<Symbol, dynamic> oldProps,
                            Map<Symbol, dynamic> newProps) {

    // Delete any removed props
    for (Symbol key in oldProps.keys) {
      if (newProps.containsKey(key)) {
        continue;
      }

      var type = tag.getPropType(key);
      if (type is HandlerType) {
        removeHandler(type, eltPath);
      } else if (type is AttributeType) {
        dom.removeAttribute(eltPath, type.name);
      }
    }

    // Update any new or changed props
    for (Symbol key in newProps.keys) {
      var oldVal = oldProps[key];
      var newVal = newProps[key];
      if (oldVal == newVal) {
        continue;
      }

      var type = tag.getPropType(key);
      if (type is HandlerType) {
        setHandler(type, eltPath, newVal);
        continue;
      } else if (type is AttributeType) {
        String val = _makeDomVal(key, newVal);
        dom.setAttribute(eltPath, type.name, val);
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