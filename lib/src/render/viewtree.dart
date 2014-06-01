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
abstract class _View {
  /// The unique id used to find the view's HTML element.
  final String path;

  /// The depth of this node in the view tree (not in the DOM).
  final int depth;

  final Renderer renderer;

  /// The owner's reference to the DOM. May be null.
  final ref;

  TaggedNode node;

  _View(this.path, this.depth, this.renderer, this.ref, this.node);

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
class _TextView extends _View {
  _TextView(String path, int depth, _TextNode node) :
    super(path, depth, null, null, node);

  _TextNode get node => super.node;
}

/// A view node for a rendered HTML element.
class _EltView extends _View {
  final String tagName;
  // Non-null if the element has at least one non-text child.
  List<_View> _children;
  // Non-null if the view contains just text.
  String _childText;

  _EltView(ElementNode node, String path, int depth) :
      tagName = node.eltTag.type.name,
      super(path, depth, null, node["ref"], node) {
  }

  ElementNode get node => super.node;
  ElementTag get eltTag => node.eltTag;
}

/// A view node for a rendered template.
class _TemplateView extends _View {
  _View shadow;
  _TemplateView(String path, int depth, Renderer render, TaggedNode node) :
    super(path, depth, render, null, node);

  _TemplateRenderer get renderer => super.renderer;
}

typedef _InvalidateWidgetFunc(_WidgetView v);

/// A view node for a rendered widget.
class _WidgetView extends _View {
  WidgetController controller;
  _View shadow;

  _WidgetView(String path, int depth, _WidgetRenderer render, TaggedNode node) :
    super(path, depth, render, null, node);

  _WidgetRenderer get renderer => super.renderer;

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
