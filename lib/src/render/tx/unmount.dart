part of render;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  void releaseElement(String path, ref, {bool willReplace: false});

  /// Recursively frees resources in a node tree. Marks all nodes as unmounted.
  /// Calls releaseElement() on each HTML element in the tree.
  /// Doesn't change the DOM; this is up to the caller.
  void unmount(_Node node, {bool willReplace: false}) {
    if (node is _ExpandedNode) {
      unmount(node.shadow, willReplace: willReplace);
      node.shadow = null;
      node.expander.unmount();
    } else if (node is _ElementNode) {
      unmountInner(node);
      releaseElement(node.path, node.view.ref, willReplace: willReplace);
    } else {
      throw "unknown node type";
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