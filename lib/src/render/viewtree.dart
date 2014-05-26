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
  final Tag tag;

  /// The unique id used to find the view's HTML element.
  final String path;

  /// The depth of this node in the view tree (not in the DOM).
  final int depth;

  /// The owner's reference to the DOM. May be null.
  final ref;

  TagNode node;

  _View(TagNode node, this.path, this.depth) :
    this.tag = node.tag,
    this.ref = node[#ref],
    this.node = node;

  bool get mounted => node != null;

  TagNode updateProps(TagNode newNode) {
    assert(node != null);
    assert(tag == newNode.tag);
    var old = node;
    node = newNode;
    return old;
  }

  void _unmount() {
    assert(node != null);
    node = null;
  }
}

/// A node representing some plain text that was rendered as a <span>.
///
/// To simulate mixed-content HTML, we render plain text inside a <span>, so that
/// it can easily be updated using its data-path attribute.
class _Text extends _View {
  _Text(String path, int depth, String value) :
    super(new TagNode(const _TextTag(), {#value: value}), path, depth);
}

class _TextTag extends Tag {
  const _TextTag() : super(null);
}

/// A node representing a rendered HTML element.
class _Elt extends _View {
  final String tagName;
  // Non-null if the element has at least one non-text child.
  List<_View> _children;
  // Non-null if the view contains just text.
  String _childText;

  _Elt(TagNode node, String path, int depth) :
      tagName = node.tag.type.name,
      super(node, path, depth) {
  }
}

/// A node representing a rendered template.
class _Template extends _View {
  _View shadow;
  _Template(TagNode node, String path, int depth) : super(node, path, depth);
}

typedef _InvalidateWidgetFunc(_Widget v);

/// A node representing a rendered widget.
class _Widget extends _View {
  WidgetController controller;
  _View shadow;

  _Widget(TagNode node, String path, int depth) : super(node, path, depth);

  @override
  TagNode updateProps(TagNode next) {
    assert(controller.widget.isMounted);
    TagNode old = node;
    if (next != null) {
      super.updateProps(next);
      controller.widget.setProps(next);
    }
    return old;
  }
}
