part of render;

/// A View is a record of how a Tag was rendered to the DOM.
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
/// Each View conceptually has an owner that rendered its corresponding Tag. For top-level
/// tags that aren't in a shadow tree, the owner is outside the framework and makes changes
/// by calling Root.mount(). For Views inside a shadow tree, the owner is the template or
/// widget whose render method created the shadow tree.
///
/// Most Views have no state of their own; all their state is copied from the corresponding
/// Tag. Therefore, they only need to be updated when their owner is rendered. However,
/// widgets have their own state and therefore can start a render on their own by calling
/// Widget.invalidate().
abstract class _View {

  final TagDef def;

  /// The unique id used to find the view's HTML element.
  final String path;

  /// The depth of this node in the view tree (not in the DOM).
  final int depth;

  /// The owner's reference to the DOM. May be null.
  final ref;

  bool _mounted = true;

  _View(this.def, this.path, this.depth, this.ref);

  void _unmount() {
    assert(_mounted);
    _mounted = false;
  }
}

/// A node representing some plain text that was rendered as a <span>.
///
/// To simulate mixed-content HTML, we render plain text inside a <span>, so that
/// it can easily be updated using its data-path attribute.
class _Text extends _View {
  String value;
  _Text(String path, int depth, this.value) : super(TextDef.instance, path, depth, null);
}

/// A node representing a rendered HTML element.
class _Elt extends _View {
  final String tagName;
  Map<Symbol, dynamic> props;
  // Non-null if the element has at least one non-text child.
  List<_View> _children;
  // Non-null if the view contains just text.
  String _childText;

  _Elt(EltDef def, String path, int depth, Map<Symbol, dynamic> propMap) :
      tagName = def.tagName,
      props = propMap,
      super(def, path, depth, propMap[#ref]) {
  }
}

/// A node representing a rendered template.
class _Template extends _View {
  Props props;
  _View shadow;

  _Template(TemplateDef def, String path, int depth, Map<Symbol, dynamic> propsMap) :
    super(def, path, depth, propsMap[#ref]);
}

typedef _InvalidateWidgetFunc(_Widget v);

/// A node representing a rendered widget.
class _Widget extends _View {
  WidgetController controller;
  _View shadow;

  Widget get widget => controller.widget;

  _Widget(WidgetDef def, String path, int depth, ref) : super(def, path, depth, ref);
}