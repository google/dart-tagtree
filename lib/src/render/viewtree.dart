part of render;

/// A View records how a TagNode was rendered in the most recent animation frame.
///
/// Each Root has a tree of Views that records how its DOM was last rendered.
/// Between animation frames, the view tree should match the DOM. When rendering an
/// animation frame, a Transaction updates the view tree to the new state of the DOM.
///
/// Performing this update is a way of calculating all the changes that need to be made
/// to the DOM. See Transaction and its mixins for the update calculation and
/// DomUpdater which is the API used to send a stream of updates to the DOM.
///
/// There are View subclasses for each kind of Tag: HTML elements, templates,
/// and widgets. (To support mixed content, there is also a View subclass for plain
/// text.) Templates and widgets have shadow view trees recording the output of their
/// render methods. To calculate the current state of the DOM, we could recursively
/// replace each view with its shadow, resulting in a tree containing only element
/// and text nodes.
///
/// Each View conceptually has an owner that rendered the corresponding TagNode. For top-level
/// tags that aren't in a shadow tree, the owner is outside the framework and makes changes
/// by calling Root.mount(). For Views inside a shadow tree, the owner is the template or
/// widget node whose render method created the shadow tree.
///
/// Most Views have no state of their own; all their state is copied from the corresponding
/// Tag. Therefore, they only need to be updated when their owner is rendered. However,
/// widgets have their own state and therefore can start a render by calling
/// Widget.invalidate().
abstract class _View<N extends TaggedNode> {
  /// The unique id used to find the view's HTML element.
  final String path;

  /// The depth of this node in the view tree (not in the DOM).
  final int depth;

  N node;

  _View(this.path, this.depth, this.node);

  bool get mounted => node != null;

  TaggedNode updateProps(TaggedNode newNode) {
    assert(node != null);
    var old = node;
    node = newNode;
    return old;
  }

  void _unmount() {
    assert(node != null);
    node = null;
  }
}

/// A view node for some text within mixed-content HTML.
///
/// To simulate mixed-content HTML, we render the text inside a <span>,
/// so that it can easily be updated using its data-path attribute.
class _TextView extends _View<_TextNode> {
  _TextView(String path, int depth, _TextNode node) : super(path, depth, node);
}

/// A view node for a rendered HTML element.
class _EltView extends _View<ElementNode> {
  final ElementType type;
  // Non-null if the element has at least one non-text child.
  List<_View> _children;
  // Non-null if the view contains just text.
  String _childText;

  _EltView(String path, int depth, TaggedNode node, this.type) : super(path, depth, node);

  ElementNode get node => super.node;
}

/// A view node for a rendered template.
class _TemplateView extends _View<TaggedNode> {
  final TemplateFunc render;
  final ShouldRenderFunc shouldRender;
  _View shadow;
  _TemplateView(String path, int depth, TaggedNode node, this.render, this.shouldRender) :
    super(path, depth, node);
}

typedef _InvalidateWidgetFunc(_WidgetView v);

/// A view node for a rendered widget.
class _WidgetView extends _View<TaggedNode> {
  CreateWidgetFunc createWidget;
  WidgetController controller;
  _View shadow;

  _WidgetView(String path, int depth, TaggedNode node, this.createWidget) :
    super(path, depth, node);

  @override
  TaggedNode updateProps(TaggedNode next) {
    assert(controller.widget.isMounted);
    TaggedNode old = node;
    if (next != null) {
      super.updateProps(next);
      controller.widget.setProps(next);
    }
    return old;
  }
}
