part of core;

/// A callback function for traversing the tree.
typedef Visitor(View v);

/// A View is a node in a view tree.
///
/// A View can can be an HTML Element ("Elt"), plain text ("Text"), or a Widget.
/// Each Widget generates a "shadow" view tree to represent it. To calculate the HTML
/// that will actually be displayed, recursively replace each Widget with its shadow,
/// resulting in a tree containing only Elt and Text nodes.
///
/// Conceptually, each View has a set of *props*, which are a generalization of HTML
/// attributes. Props are always passed in as arguments to a View constructor, but may
/// be copied from one View to another of the same type using an updateTo() call.
/// (Exactly how this happens depends on the view.)
///
/// In addition, some views may have internal state, which can change in response to
/// events. When a Widget changes state, its shadow must be re-rendered. When
/// re-rendering, we attempt to preserve as many View nodes as possible by updating them
/// in place. This is both more efficient and preserves state.
abstract class View {

  /// The owner's reference to this View. May be null.
  final Ref _ref;

  bool _mounted = false;
  String _path;
  int _depth;

  View(this._ref);

  /// Returns a unique id used to find the view's HTML element.
  ///
  /// Non-null when mounted.
  String get path => _path;

  /// The depth of this node in the view tree. Non-null when mounted;
  int get depth => _depth;

  /// Returns the view's current props.
  Props get props;

  /// Writes the view tree to HTML and assigns an id to each View.
  ///
  /// The path should be a string starting with "/" and using "/" as a separator,
  /// for example "/asdf/1/2/3", chosen to ensure uniqueness in the DOM.
  /// The path of a child View is created by appending a suffix starting with "/" to its
  /// parent. When rendered to HTML, the path will show up in the data-path attribute.
  ///
  /// A Widget has the same path as the root node in its shadow tree (recursively).
  void mount(StringBuffer out, String path, int depth) {
    _path = path;
    _depth = depth;
    _mounted = true;
    if (_ref != null) {
      _ref._set(this);
    }
    doMount(out);
  }

  /// Frees resources associated with this View and all its descendants
  /// and marks them as unmounted. This removes any references to the DOM,
  /// but doesn't actually change the DOM.
  void unmount(NextFrame frame) {
    willUnmount();
    if (_ref != null) {
      _ref._set(null);
    }
    doUnmount(frame);
    frame.detachElement(_path);
    _mounted = false;
  }

  /// Subclass hook for implementing mount.
  void doMount(StringBuffer out);

  /// Lifecycle method called after the DOM element is ready.
  void didMount() {}

  /// Lifecycle method called before the DOM element is removed.
  void willUnmount() {}

  /// Subclass hook for implementing unmount.
  void doUnmount(NextFrame frame);

  /// Performs a post-order traversal of all the views in the view tree.
  void traverse(Visitor callback);

  /// Returns true if we can do an in-place update that sets the props to those of the given view.
  ///
  /// If so, we can call refresh(). Otherwise, we must unmount the view and mount its replacement,
  /// so all state will be lost.
  bool canUpdateTo(View nextVersion);

  /// Updates a view in place.
  ///
  /// After the update, it should have the same props as nextVersion and any DOM changes
  /// needed should have been sent to nextFrame for rendering.
  ///
  /// If nextVersion is null, the props are unchanged, but a stateful view may apply any pending
  /// state.
  ///
  /// (This should only be called by the framework; it is called within a
  /// requestAnimationFrame callback.)
  void update(View nextVersion, Root root, NextFrame nextFrame);

  /// Lifecycle hook called after the DOM has been updated.
  void didUpdate() {}
}

/// Holds a reference to a view.
///
/// This is typically passed via a "ref" property. It's valid
/// when the view is mounted and automatically cleared on unmount.
class Ref {
  View _view;

  View get view => _view;

  /// Subclass hook for cleaning up on unmount.
  void onDetach() {}

  void _set(View target) {
    _view = target;
    if (_view == null) {
      onDetach();
    }
  }
}

/// A wrapper allowing a View's props to be accessed using dot notation.
@proxy
class Props {
  final Map<Symbol, dynamic> _props;

  Props(this._props);

  noSuchMethod(Invocation inv) {
    if (inv.isGetter) {
      if (_props.containsKey(inv.memberName)) {
        return _props[inv.memberName];
      }
    }
    return super.noSuchMethod(inv);
  }
}
