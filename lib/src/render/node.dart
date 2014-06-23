part of render;

typedef void _InvalidateFunc(_ExpandedNode node);

/// A _Node records how a [View] was rendered in the most recent animation frame.
///
/// Each [RenderRoot] has a tree of nodes that records how the DOM was last rendered.
/// Between animation frames, the tree should match the DOM. When rendering an
/// animation frame, a Transaction updates the tree (in place) to the new state
/// of the DOM.
///
/// Performing this update is a way of calculating all the changes that need to be made
/// to the DOM. See Transaction and its mixins for the update calculation and
/// [DomUpdater] for the API used to send a stream of updates to the DOM.
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
abstract class _Node<V extends View> {
  /// The unique id used to find the node's HTML element.
  final String path;

  /// The depth of this node in the node tree (not in the DOM).
  final int depth;

  /// The view that was most recently rendered into this node.
  V view;

  _Node(this.path, this.depth, this.view);


  /// The expander that was used for the last render.
  Expander get renderedExpander;

  /// The expander from the most recent call to [Refresh].
  Expander get reloadExpander;

  bool get mounted => view != null;

  /// The props that were most recently rendered.
  PropsMap get props => view.props;

  Expander chooseExpander(View nextView, Expander first);

  void _unmount() {
    assert(view != null);
    view = null;
  }
}

class _ExpandedNode extends _Node<View> {
  _InvalidateFunc invalidate;
  Expander renderedExpander;
  Expander reloadExpander;
  _Node shadow;

  _ExpandedNode(String path, int depth, View view, this.invalidate, this.renderedExpander)
      : super(path, depth, view);

  void startRender(Expander next) {
    reloadExpander = next;
    invalidate(this);
  }

  @override
  Expander chooseExpander(View nextView, Expander first) {
    var prev = reloadExpander == null ? renderedExpander : reloadExpander;
    return prev.chooseExpander(nextView, first);
  }
}

/// A node for a rendered HTML element.
class _ElementNode extends _Node<ElementView> {
  // May be a List<_Node>, String, or RawHtml.
  var children;

  _ElementNode(String path, int depth, ElementView view) :
    super(path, depth, view);

  Expander get renderedExpander => view.type;
  Expander get reloadExpander => view.type;

  @override
  Expander chooseExpander(View nextView, Expander first) => first;
}

/// Used to wrap text children in a span when emulating mixed content.
const ElementType _textType = const ElementType(#text, "span", const [innerType]);
