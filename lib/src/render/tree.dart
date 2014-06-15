part of render;

/// A _Node records how a [View] was rendered in the most recent animation frame.
///
/// Each Root has a tree of _Nodes that records how its DOM was last rendered.
/// Between animation frames, the tree should match the DOM. When rendering an
/// animation frame, a Transaction updates the view tree to the new state of the DOM.
///
/// Performing this update is a way of calculating all the changes that need to be made
/// to the DOM. See Transaction and its mixins for the update calculation and
/// DomUpdater which is the API used to send a stream of updates to the DOM.
///
/// Nodes that have been expanded have shadow trees recording the output of their
/// expand methods. To calculate the current state of the DOM, we could recursively
/// replace each _Node with its shadow, resulting in a tree containing only element
/// and text nodes.
///
/// Each _Node conceptually has an owner that rendered the corresponding View. For top-level
/// nodes that aren't in a shadow tree, the owner is outside the framework and makes changes
/// by calling Root.mount(). For nodes inside a shadow tree, the owner is the expander that
/// created the shadow tree.
///
/// Most expanders have no state of their own; all their state is copied from the corresponding
/// View. Therefore, they only need to be updated when their owner is rendered. Widgets
/// are an exception; they can call invalidate() to add the Widget as a root for the
/// next render.
class _Node<V extends View> {
  /// The unique id used to find the node's HTML element.
  final String path;

  /// The depth of this node in the node tree (not in the DOM).
  final int depth;

  /// The view that was most recently rendered into this node.
  V view;

  /// The expander that was most recently used to render this node.
  Expander expander;

  /// The shadow if this node was expanded.
  _Node shadow;

  _Node(this.path, this.depth, this.view, this.expander);

  bool get mounted => view != null;

  /// The props that were most recently rendered.
  PropsMap get props => view.props;

  void _unmount() {
    assert(view != null);
    view = null;
  }
}

/// A node for a rendered HTML element.
class _ElementNode extends _Node<ElementView> {
  // May be a List<_Node>, String, or RawHtml.
  var children;
  _ElementNode(String path, int depth, ElementView view) : super(path, depth, view, view.type);
}
