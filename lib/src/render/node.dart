part of render;

typedef void _InvalidateFunc(_AnimatedNode node);

/// A _Node records how a [View] was rendered in the most recent animation frame.
///
/// Each [RenderRoot] has a tree of nodes that records how the DOM was last rendered.
/// Between animation frames, the tree should match the DOM. When rendering an
/// animation frame, a [Transaction] updates the tree (in place) to the new state
/// of the DOM.
///
/// Performing this update is a way of calculating all the changes that need to be made
/// to the DOM. See Transaction and its mixins for the update calculation and
/// [DomUpdater] for the API used to send a stream of updates to the DOM.
///
/// There are two subclasses, [_AnimatedNode] and [_ElementNode]. An animated node has
/// a shadow tree recording the output from the last time it was rendered. To calculate
/// the current state of the DOM, we could recursively replace each animated node with its
/// shadow, resulting in a tree containing only element nodes.
///
/// Each node conceptually has an owner that rendered its input View. For top-level
/// nodes that aren't in a shadow tree, the owner is outside the framework and makes changes
/// by calling Root.mount(). For nodes inside a shadow tree, the owner is the [Animator] that
/// rendered the shadow tree.
abstract class _Node {
  /// The unique id used to find the node's HTML element.
  final String path;

  /// The depth of this node in the node tree (not in the DOM).
  final int depth;

  _Node(this.path, this.depth);

  bool get isMounted;
  void unmount();
}

class _AnimatedNode extends _Node implements PlaceImpl {
  _InvalidateFunc _invalidate;
  bool _isDirty = true;
  Animator anim;
  _Node shadow;

  @override
  View view;

  @override
  OnRendered onRendered;

  @override
  Animator nextAnimator;

  Place _place;

  _AnimatedNode(String path, int depth, View view, Animator anim, this._invalidate) :
    super(path, depth) {

    this.view = view;
    this.anim = anim;
    _place = anim.makePlace(this, view);
    assert(_place != null);
  }

  @override
  void invalidate() {
    if (isMounted) {
      _invalidate(this);
      _isDirty = true;
    }
  }

  bool get isMounted => _place != null;

  View renderFrame(View nextView) {
    _place.commitState();
    view = nextView;
    View out = anim.renderFrame(_place);
    _isDirty = false;
    return out;
  }

  bool playWhile(Animator next) {
    nextAnimator = next;
    return anim.playWhile(_place);
  }

  bool isDirty(View next) {
    _isDirty = _isDirty || anim.needsRender(view, next);
    return _isDirty;
  }

  void unmount() {
    anim.onEnd(_place);

    view = null;
    _invalidate = null;
    anim = null;
    _place = null;
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
  Animator get anim => view.type;
  Animator get reloadExpander => view.type;

  void unmount() {
    view = null;
    children = null;
  }
}

/// Used to wrap text children in a span when emulating mixed content.
const ElementType _textType = const ElementType(#text, "span", const [innerType]);
