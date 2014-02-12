library viewlet;

import 'dart:html';
import 'dart:convert';

part 'src/inner.dart';
part 'src/elt.dart';
part 'src/event.dart';
part 'src/dom.dart';
part 'src/tags.dart';
part 'src/widget.dart';

// infrastructure

int idCounter = 0;
Map<String, View> idToTree = {};
List<LifecycleHandler> didMountQueue = [];

void mount(View tree, HtmlElement container) {
  StringBuffer out = new StringBuffer();
  String id = "/${idCounter}"; idCounter++;
  tree.mount(out, id, 0);
  setInnerHtml(container, out.toString());

  for (LifecycleHandler h in didMountQueue) {
    h();
  }
  didMountQueue.clear();

  listenForEvents(container);
  idToTree[id] = tree;
}

typedef LifecycleHandler();

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
  LifecycleHandler didMount, willUnmount;

  Ref _ref;
  bool _mounted = false;
  String _path;
  int _depth;
  View _nextVersion;

  View(this._ref);

  /// Returns a unique id used to find the view's HTML element.
  ///
  /// Non-null when mounted.
  String get path => _path;

  /// The depth of this node in the view tree. Non-null when mounted;
  int get depth => _depth;

  /// Returns the view's current props (for debugging).
  Map<Symbol,dynamic> get props;

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
    if (didMount != null) {
      didMountQueue.add(didMount);
    }
  }

  /// Frees resources associated with this View, not including any DOM nodes.
  void unmount() {
    if (willUnmount != null) {
      willUnmount();
    }
    if (_ref != null) {
      _ref._set(null);
    }
    _mounted = false;
  }

  /// Returns true if we can do an in-place update that sets the props to those of the given view.
  ///
  /// If so, we can call refresh(). Otherwise, we must unmount the view and mount its replacement,
  /// so all state will be lost.
  bool canUpdateTo(View nextVersion);

  /// Updates a view in place. After the update, it should have the same properties as nextVersion.
  /// If nextVersion is null, the props are unchanged, but a stateful view may apply any pending
  /// state.
  /// (This should only be called by the framework.)
  void update(View nextVersion);

  /// Returns the actual DOM element. Valid only when mounted.
  Element getDom() {
    assert(_mounted);
    return querySelector("[data-path=\"${_path}\"]");
  }
}

/// Holds a reference to a view.
///
/// This is typically passed via a "ref" property. It's valid
/// when the view is mounted and automatically cleared on unmount.
class Ref {
  View _view;

  View get view => _view;
  Element getDom() => _view.getDom();

  void _set(View target) {
    _view = target;
  }
}

/// A plain text view.
///
/// The framework needs to find the corresponding DOM element using a query on a
/// data-path attribute, so the text is actually rendered inside a <span>.
/// (We can't support mixed-content HTML directly and instead use a list of Elt and
/// Text views as the closest equivalent.)
///
/// However, if the parent's "inner" property is just a string, it's handled as a
/// special case and the Text class isn't used.
class Text extends View {
  String value;
  Text(this.value, {Ref ref}) : super(ref);

  Map<Symbol,dynamic> get props => {#value: value};

  void mount(StringBuffer out, String path, int depth) {
    super.mount(out, path, depth);
    // need to surround with a span to support incremental updates to a child
    out.write("<span data-path=${path}>${HTML_ESCAPE.convert(value)}</span>");
  }

  void unmount() {}

  bool canUpdateTo(View other) => (other is Text);

  void update(Text nextVersion) {
    print("refresh Text: ${_path}");

    if (nextVersion == null || value == nextVersion.value) {
      return; // no internal state to update
    }
    value = nextVersion.value;
    Element elt = querySelector("[data-path=\"${_path}\"]");
    elt.text = value;
  }
}

