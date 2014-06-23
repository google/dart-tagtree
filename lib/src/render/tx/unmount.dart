part of render;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  void releaseElement(String path, ref, {bool willReplace: false});

  /// Recursively frees resources in a node tree. Marks all nodes as unmounted.
  /// Calls releaseElement() on each HTML element in the tree.
  /// Doesn't change the DOM; this is up to the caller.
  void unmount(_Node node, {bool willReplace: false}) {
    if (node is _AnimatedNode) {

      node.invalidate = null;

      // This is first so that the parent cleans up before the children.
      node.anim.willUnmount();
      node.anim = null;

      // Recurse.
      unmount(node.shadow, willReplace: willReplace);
      node.shadow = null;

    } else if (node is _ElementNode) {
      // Recurse.
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
        // Recurse.
        unmount(child);
      }
    }
    elt.children = null;
  }
}