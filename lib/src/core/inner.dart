part of core;

/// A mixin that implements the 'inner' property of an Elt.
/// This can be text, a list of child views, or nothing.
/// (Mixed content isn't directly supported. Instead, Elt automatically
/// wraps strings in Text views.)
abstract class _Inner {

  // Non-null when the Elt is mounted and it has at least one child.
  List<View> _children = null;
  // Non-null when the Elt is mounted and it contains just text.
  String _childText = null;

  // The Elt's path.
  String get path;

  // The Elt's depth.
  int get depth;
}
