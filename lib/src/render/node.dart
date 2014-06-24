part of render;

typedef void _InvalidateFunc(_AnimatedNode node);

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
abstract class _Node {
  /// The unique id used to find the node's HTML element.
  final String path;

  /// The depth of this node in the node tree (not in the DOM).
  final int depth;

  _Node(this.path, this.depth);

  bool get isMounted;
  void _unmount();
}

class _AnimatedNode extends _Node {
  View renderedView;
  _InvalidateFunc invalidate;
  Animation anim;
  _Node shadow;
  var _renderedState;
  var _state;

  _AnimatedNode(String path, int depth, View view, this.invalidate, this.anim)
      : super(path, depth) {
    _state = anim.getFirstState(view);
  }

  bool get isMounted => renderedView != null;

  View expand(View nextView) {
    renderedView = nextView;
    _renderedState = _state;
    return anim.expand(renderedView, _renderedState, refresh);
  }

  bool shouldExpand(View next) => anim.shouldExpand(renderedView, _renderedState, next, _state);

  void refresh(Step step) {
    if (isMounted) {
      _state = step(_state);
      invalidate(this);
    }
  }

  void _unmount() {
    renderedView = null;
    invalidate = null;
    anim.willUnmount();
    anim = null;
    shadow = null;
  }
}

/// A node for a rendered HTML element.
class _ElementNode extends _Node {
  ElementView view;
  // May be a List<_Node>, String, or RawHtml.
  var children;

  _ElementNode(String path, int depth, this.view) : super(path, depth);

  bool get isMounted => view != null;

  PropsMap get props => view.props;
  Animation get anim => view.type;
  Animation get reloadExpander => view.type;

  void _unmount() {
    view = null;
    children = null;
  }
}

/// Used to wrap text children in a span when emulating mixed content.
const ElementType _textType = const ElementType(#text, "span", const [innerType]);
