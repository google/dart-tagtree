part of core;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  void releaseElement(String path, ref, {bool willReplace: false});

  /// Frees resources associated with this View and all its descendants
  /// and marks them as unmounted. (Calls releaseElement but doesn't actually
  /// change the DOM.)
  void unmount(_View v, {bool willReplace: false}) {
    if (v is _Text) {
      releaseElement(v.path, v.ref, willReplace: willReplace);
    } else if (v is _Elt) {
      unmountInner(v);
      releaseElement(v.path, v.ref, willReplace: willReplace);
    } else if (v is _Template) {
      unmount(v._shadow);
      v._shadow = null;
    } else if (v is _WidgetView) {
      _unmountWidget(v, willReplace);
    } else {
      throw "unable to unmount ${v.runtimeType}";
    }
    v._unmount();
  }

  void _unmountWidget(_WidgetView view, bool willReplace) {
    if (view._shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    if (view.widget._willUnmount.hasListener) {
      view.widget._willUnmount.add(true);
    }
    unmount(view._shadow, willReplace: willReplace);
    view._shadow = null;
  }

  void unmountInner(_Inner elt) {
    if (elt._children != null) {
      for (_View child in elt._children) {
        unmount(child);
      }
      elt._children = null;
    }
    elt._childText = null;
  }
}