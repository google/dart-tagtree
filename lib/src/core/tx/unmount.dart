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
      unmount(v.shadow);
      v.shadow = null;
    } else if (v is _Widget) {
      _unmountWidget(v, willReplace);
    } else {
      throw "unable to unmount ${v.runtimeType}";
    }
    v._unmount();
  }

  void _unmountWidget(_Widget view, bool willReplace) {
    if (view.shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    if (view.widget._willUnmount.hasListener) {
      view.widget._willUnmount.add(true);
    }
    unmount(view.shadow, willReplace: willReplace);
    view.shadow = null;
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