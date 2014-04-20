part of core;


/// A View is a node in the internal view tree.
///
/// A View can can be an HTML Element ("Elt"), plain text ("Text"), a Template, or a Widget.
/// Each Template and Widget generates a shadow view tree to represent it. To calculate the HTML
/// that will actually be displayed, recursively replace each view with its shadow,
/// resulting in a tree containing only Elt and Text nodes.
///
/// Conceptually, each View has a set of *props*, which are a generalization of HTML
/// attributes. Props are always passed in from the outside, but may
/// be copied from one View to another of the same type using an update.
/// (Exactly how this happens depends on the view.)
///
/// In addition, some views may have internal state, which can change in response to
/// events. When a Widget changes state, its shadow must be re-rendered. When
/// re-rendering, we attempt to preserve as many View nodes as possible by updating them
/// in place. This is both more efficient and preserves state.
abstract class _View {

  final TagDef def;

  /// The unique id used to find the view's HTML element.
  final String path;

  /// The depth of this node in the view tree (not in the DOM).
  final int depth;

  /// The owner's reference to this View. May be null.
  final BaseRef ref;

  bool _mounted = true;

  _View(this.def, this.path, this.depth, this.ref);

  void _unmount() {
    assert(_mounted);
    _mounted = false;
  }
}
