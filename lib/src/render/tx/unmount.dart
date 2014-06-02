part of render;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  void releaseElement(String path, ref, {bool willReplace: false});

  /// Frees resources associated with this View and all its descendants
  /// and marks them as unmounted. (Calls releaseElement but doesn't actually
  /// change the DOM.)
  void unmount(_View v, {bool willReplace: false}) {
    if (v is _TextView) {
      releaseElement(v.path, v.node.ref, willReplace: willReplace);
    } else if (v is _EltView) {
      unmountInner(v);
      releaseElement(v.path, v.node.ref, willReplace: willReplace);
    } else if (v is _TemplateView) {
      unmount(v.shadow);
      v.shadow = null;
    } else if (v is _WidgetView) {
      _unmountWidget(v, willReplace);
    } else {
      throw "unable to unmount ${v.runtimeType}";
    }
    v._unmount();
  }

  void _unmountWidget(_WidgetView view, bool willReplace) {
    if (view.shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    if (view.controller.willUnmount.hasListener) {
      view.controller.willUnmount.add(true);
    }
    unmount(view.shadow, willReplace: willReplace);
    view.shadow = null;
  }

  void unmountInner(_EltView elt) {
    if (elt._children != null) {
      for (_View child in elt._children) {
        unmount(child);
      }
      elt._children = null;
    }
    elt._childText = null;
  }
}