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
/// There are _Node subclasses for each kind of Tag: HTML elements, templates,
/// and widgets. (To support mixed content, there is also a _Node subclass for plain
/// text.) Templates and widgets have shadow trees recording the output of their
/// render methods. To calculate the current state of the DOM, we could recursively
/// replace each _Node with its shadow, resulting in a tree containing only element
/// and text nodes.
///
/// Each _Node conceptually has an owner that rendered the corresponding View. For top-level
/// nodes that aren't in a shadow tree, the owner is outside the framework and makes changes
/// by calling Root.mount(). For nodes inside a shadow tree, the owner is the template or
/// widget node whose render method created the shadow tree.
///
/// Most _Nodes have no state of their own; all their state is copied from the corresponding
/// View. Therefore, they only need to be updated when their owner is rendered. However,
/// widgets have their own state and therefore can start a render by calling
/// Widget.invalidate().
abstract class _Node<V extends View> {
  /// The unique id used to find the node's HTML element.
  final String path;

  /// The depth of this node in the node tree (not in the DOM).
  final int depth;

  /// The view that was most recently rendered into this node.
  V view;

  _Node(this.path, this.depth, this.view);

  bool get mounted => view != null;

  /// The props that were most recently rendered.
  PropsMap get props => view.props;

  View updateProps(View newView) {
    assert(view != null);
    var old = view;
    view = newView;
    return old;
  }

  void _unmount() {
    assert(view != null);
    view = null;
  }
}

/// A node for some text within mixed-content HTML.
///
/// To simulate mixed-content HTML, we render the text inside a <span>,
/// so that it can easily be updated using its data-path attribute.
class _TextNode extends _Node<_TextView> {
  _TextNode(String path, int depth, _TextView node) : super(path, depth, node);
}

/// A node for a rendered HTML element.
class _ElementNode extends _Node<ElementView> {
  // May be a List<_Node>, String, or RawHtml.
  var children;
  _ElementNode(String path, int depth, View node) : super(path, depth, node);
}

/// A node for a expanded template.
class _TemplateNode extends _Node<View> {
  final TemplateFunc render;
  final ShouldRenderFunc shouldRender;
  _Node shadow;
  _TemplateNode(String path, int depth, View node, this.render, this.shouldRender) :
    super(path, depth, node);
}

typedef _InvalidateWidgetFunc(_WidgetNode v);

/// A node for a running widget.
class _WidgetNode extends _Node<View> {
  CreateWidgetFunc createWidget;
  WidgetController controller;
  _Node shadow;

  _WidgetNode(String path, int depth, View node, this.createWidget) :
    super(path, depth, node);

  @override
  View updateProps(View next) {
    assert(controller.widget.isMounted);
    View old = view;
    if (next != null) {
      super.updateProps(next);
      controller.widget.setView(next);
    }
    return old;
  }
}
