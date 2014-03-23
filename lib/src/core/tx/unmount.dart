part of core;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  void releaseElement(String path, String tag);

  /// Frees resources associated with this View and all its descendants
  /// and marks them as unmounted. (Calls releaseElement but doesn't actually
  /// change the DOM.)
  void unmount(View v) {
    if (v is Text) {
      releaseElement(v.path, "span");
    } else if (v is Elt) {
      unmountInner(v);
      releaseElement(v.path, v.tagName);
    } else if (v is Widget) {
      _unmountWidget(v);
    } else {
      throw "unable to unmount ${v.runtimeType}";
    }
    if (v._ref != null) {
      v._ref._set(null);
    }
    v._unmount();
  }

  void _unmountWidget(Widget w) {
    if (w._shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    if (w._willUnmount.hasListener) {
      w._willUnmount.add(true);
    }
    unmount(w._shadow);
    w._shadow = null;
  }

  void unmountInner(_Inner elt) {
    if (elt._children != null) {
      for (View child in elt._children) {
        unmount(child);
      }
      elt._children = null;
    }
    elt._childText = null;
  }
}