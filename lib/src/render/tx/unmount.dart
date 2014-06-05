part of render;

/// A Transaction mixin that implements unmounting views.
abstract class _Unmount {

  // What was unmounted
  void releaseElement(String path, ref, {bool willReplace: false});

  /// Frees resources associated with this View and all its descendants
  /// and marks them as unmounted. (Calls releaseElement but doesn't actually
  /// change the DOM.)
  void unmount(_Node node, {bool willReplace: false}) {
    if (node is _TextNode) {
      releaseElement(node.path, node.view.ref, willReplace: willReplace);
    } else if (node is _ElementNode) {
      unmountInner(node);
      releaseElement(node.path, node.view.ref, willReplace: willReplace);
    } else if (node is _TemplateNode) {
      unmount(node.shadow);
      node.shadow = null;
    } else if (node is _WidgetNode) {
      _unmountWidget(node, willReplace);
    } else {
      throw "unable to unmount ${node.runtimeType}";
    }
    node._unmount();
  }

  void _unmountWidget(_WidgetNode node, bool willReplace) {
    if (node.shadow == null) {
      throw "not mounted: ${this.runtimeType}";
    }
    if (node.controller.willUnmount.hasListener) {
      node.controller.willUnmount.add(true);
    }
    unmount(node.shadow, willReplace: willReplace);
    node.shadow = null;
  }

  void unmountInner(_ElementNode elt) {
    if (elt._children != null) {
      for (_Node child in elt._children) {
        unmount(child);
      }
      elt._children = null;
    }
    elt._childText = null;
    elt._childHtml = null;
  }
}