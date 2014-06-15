part of render;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  void releaseElement(String path, ref, {bool willReplace: false});

  /// Frees resources associated with this View and all its descendants
  /// and marks them as unmounted. (Calls releaseElement but doesn't actually
  /// change the DOM.)
  void unmount(_Node node, {bool willReplace: false}) {
    if (node.shadow != null) {
      unmount(node.shadow, willReplace: willReplace);
      node.shadow = null;
    }
    node.expander.unmount();

    var view = node.view;
    if (view is _TextView) {
      releaseElement(node.path, view.ref, willReplace: willReplace);
    } else if (node is _ElementNode) {
      unmountInner(node);
      releaseElement(node.path, node.view.ref, willReplace: willReplace);
    }
    node._unmount();
  }

  void unmountInner(_ElementNode elt) {
    if (elt.children is List) {
      for (_Node child in elt.children) {
        unmount(child);
      }
    }
    elt.children = null;
  }
}