part of render;

/// A Transaction mixin that implements unmounting nodes.
abstract class _Unmount {

  // What was unmounted
  final List<_LayoutNode> _unmountedLayouts = [];
  void releaseElement(String path, ref, {bool willReplace: false});

  /// Recursively frees resources in a node tree. Marks all nodes as unmounted.
  /// Calls releaseElement() on each HTML element in the tree.
  /// Doesn't change the DOM; this is up to the caller.
  void unmount(_Node node, {bool willReplace: false}) {
    if (node is _AnimatedNode) {

      // Recurse.
      unmount(node.shadow, willReplace: willReplace);

    } else if (node is _ElementNode) {

      // Recurse.
      unmountInner(node);

      releaseElement(node.path, node.tag.ref, willReplace: willReplace);

    } else if (node is _ThemeNode) {

      // Recurse.
      unmount(node.shadow, willReplace: willReplace);

    } else if (node is _LayoutNode) {

      // Recurse.
      unmount(node.shadow, willReplace: willReplace);

      _unmountedLayouts.add(node);

    } else {
      throw "unknown node type";
    }

    node.unmount();
  }

  void unmountInner(_ElementNode node ) {
    if (node.children is List) {
      for (_Node child in node.children) {
        // Recurse.
        unmount(child);
      }
    }
    node.children = null;
  }
}