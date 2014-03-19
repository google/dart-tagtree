part of core;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  final List<String> _unmountedPaths = [];
  final List<String> _unmountedFormPaths = [];
  void removeHandlersForPath(String path);

  /// Frees resources associated with this View and all its descendants
  /// and marks them as unmounted. This removes any references to the DOM,
  /// but doesn't actually change the DOM.
  void unmount(View v) {
    if (v is Text) {
      // nothing to do
    } else if (v is Widget) {
      _unmountWidget(v);
    } else if (v is Elt) {
      _unmountElt(v);
    } else {
      throw "unable to unmount ${v.runtimeType}";
    }
    if (v._ref != null) {
      v._ref._set(null);
    }
    _unmountedPaths.add(v._path);
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

  void _unmountElt(Elt elt) {
    unmountInner(elt);
    removeHandlersForPath(elt.path);
    if (elt.tagName == "form") {
      _unmountedFormPaths.add(elt.path);
    }
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